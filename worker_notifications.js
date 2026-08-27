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
        let usersQuery = db.collection('utilisateurs');
        
        if (cible === 'clients') {
          // On filtre sur les clients. NB: Dans cette architecture, les clients sont dans 'clients' ou 'utilisateurs' avec un role
          // Si les données sont séparées, on cherche dans la collection spécifique, sinon on filtre par role.
          // En supposant que le role est stocké dans l'utilisateur, ou bien on interroge directement la sous-collection.
          // Pour la démo, on cherche tous les tokens qui ont une propriété fcmToken
        }
        
        // Afin de s'assurer d'avoir les tokens, on prend simplement tous les documents de 'utilisateurs' qui ont 'fcmToken'
        const usersSnap = await usersQuery.where('fcmToken', '!=', null).get();
        
        const tokens = [];
        usersSnap.forEach(userDoc => {
          const userData = userDoc.data();
          
          // Filtrage local selon la cible si le champ 'role' existe
          if (cible === 'clients' && userData.role !== 'client') return;
          if (cible === 'transporteurs' && userData.role !== 'transporteur') return;
          
          if (userData.fcmToken) {
            tokens.push(userData.fcmToken);
          }
        });

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
