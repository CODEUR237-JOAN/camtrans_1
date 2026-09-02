/**
 * worker_notifications.js
 * 
 * Script Node.js tournant en arrière-plan pour expédier les notifications Push (FCM).
 * Il écoute la collection `notifications_push` de Firestore et utilise le SDK Firebase Admin.
 * 
 * UTILISATION : node worker_notifications.js
 */

const { initializeApp, cert } = require('firebase-admin/app');
const { getMessaging } = require('firebase-admin/messaging');
const { getFirestore } = require('firebase-admin/firestore');
const serviceAccount = require('./serviceAccountKey.json');

// Initialisation de Firebase Admin
initializeApp({
  credential: cert(serviceAccount),
});

const db = getFirestore();
const messaging = getMessaging();

console.log("🚀 Worker de Notifications Démarré ! En écoute sur 'notifications_push'...\n");

db.collection('notifications_push')
  .where('status', '==', 'pending')
  .onSnapshot(async (snapshot) => {
    if (snapshot.empty) return;

    for (const doc of snapshot.docs) {
      const notifData = doc.data();
      const notifId = doc.id;
      const { titre, message, cible } = notifData;

      console.log(`\n🔔 Nouvelle notification Push interceptée: [${titre}] (Cible: ${cible})`);

      try {
        // Mettre à jour le statut pour éviter les doubles envois
        await db.collection('notifications_push').doc(notifId).update({ status: 'processing' });

        // 1. Récupérer les utilisateurs selon la cible
        let tokens = [];

        if (notifData.cibleId) {
            // Envoi à un utilisateur spécifique
            const collectionName = cible === 'client' ? 'clients' : 'transporteurs';
            const userDoc = await db.collection(collectionName).doc(notifData.cibleId).get();
            if (userDoc.exists && userDoc.data().fcmToken) {
                tokens.push(userDoc.data().fcmToken);
            }
        } else {
            // Envoi groupé (ancien comportement)
            const collectionName = cible === 'clients' ? 'clients' : (cible === 'transporteurs' ? 'transporteurs' : 'utilisateurs');
            const usersSnap = await db.collection(collectionName).where('fcmToken', '!=', null).get();
            usersSnap.forEach(userDoc => {
                if (userDoc.data().fcmToken) {
                    tokens.push(userDoc.data().fcmToken);
                }
            });
        }

        if (tokens.length === 0) {
          console.log(`⚠️ Aucun token trouvé pour la cible '${cible}'.`);
          await db.collection('notifications_push').doc(notifId).update({ status: 'sent', tokensCount: 0 });
          continue;
        }

        console.log(`📡 Envoi de la notification à ${tokens.length} appareils...`);

        // 2. Préparer le payload FCM
        const payload = {
          notification: {
            title: titre,
            body: message,
          },
          tokens: tokens, // Envoi groupé (multicast)
        };

        // 3. Envoyer via Firebase Cloud Messaging
        const response = await messaging.sendEachForMulticast(payload);
        
        console.log(`✅ Push envoyé ! Succès: ${response.successCount}, Échecs: ${response.failureCount}`);

        // 4. Marquer la notification comme terminée
        await db.collection('notifications_push').doc(notifId).update({
          status: 'sent',
          tokensCount: tokens.length,
          successCount: response.successCount,
          dateSent: new Date(),
        });

      } catch (err) {
        console.error(`❌ Erreur lors de l'envoi de la notification ${notifId} :`, err);
        // On repasse en pending (ou failed)
        await db.collection('notifications_push').doc(notifId).update({ status: 'failed', error: err.message }).catch(()=>{});
      }
    }
  }, err => {
    console.error(`❌ Erreur d'écoute Firestore:`, err);
  });
