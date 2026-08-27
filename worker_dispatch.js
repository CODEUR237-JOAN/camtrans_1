/**
 * worker_dispatch.js
 * 
 * Ce script tourne en tâche de fond. Son rôle est de surveiller les nouvelles
 * courses (statut = 'en_attente') et de les assigner automatiquement au transporteur
 * disponible le plus proche ayant le bon type de véhicule.
 * 
 * UTILISATION: node worker_dispatch.js
 */

const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const serviceAccount = require('./serviceAccountKey.json');

// Initialisation (seulement si ce n'est pas déjà fait par un autre script dans le même process, mais ici c'est un process séparé)
initializeApp({
  credential: cert(serviceAccount),
});

const db = getFirestore();

// Formule de Haversine pour calculer la distance entre deux coordonnées GPS
function calculerDistanceKM(lat1, lon1, lat2, lon2) {
  const R = 6371; // Rayon de la terre en km
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
            Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
            Math.sin(dLon/2) * Math.sin(dLon/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  return R * c;
}

console.log("🤖 CamTrans Smart Dispatcher activé. En attente de courses...\n");

db.collection('courses')
  .where('statut', '==', 'en_attente')
  .onSnapshot(async (snapshot) => {
    if (snapshot.empty) return;

    for (const doc of snapshot.docs) {
      const course = doc.data();
      const courseId = doc.id;

      console.log(`\n📦 Nouvelle course détectée: ${courseId} (${course.adresseDepart} ➔ ${course.adresseArrivee})`);
      console.log(`Recherche d'un transporteur de type: ${course.typeVehicule}`);

      try {
        // 1. Récupérer les transporteurs disponibles
        const transporteursSnap = await db.collection('transporteurs')
          .where('disponible', '==', true)
          .where('documentsValides', '==', true)
          // Dans un monde idéal, on filtre aussi par type de véhicule directement dans la requête
          .get();

        if (transporteursSnap.empty) {
          console.log(`⚠️ Aucun transporteur disponible pour l'instant.`);
          continue;
        }

        let meilleurTransporteur = null;
        let distanceMin = Infinity;

        transporteursSnap.forEach(tDoc => {
          const transporteur = tDoc.data();
          
          // Filtre strict sur le type de véhicule
          if (course.typeVehicule && transporteur.categorieVehicule !== course.typeVehicule) {
              return;
          }

          // Si le transporteur a des coordonnées GPS récentes
          if (transporteur.latitude && transporteur.longitude) {
            const distance = calculerDistanceKM(
              course.latitudeDepart, course.longitudeDepart,
              transporteur.latitude, transporteur.longitude
            );

            if (distance < distanceMin) {
              distanceMin = distance;
              meilleurTransporteur = { id: tDoc.id, ...transporteur };
            }
          } else {
             // S'il n'a pas de position, on l'assigne par défaut s'il n'y a personne d'autre
             if (!meilleurTransporteur) {
                 meilleurTransporteur = { id: tDoc.id, ...transporteur };
                 distanceMin = 10; 
             }
          }
        });

        if (meilleurTransporteur) {
          console.log(`✅ Match trouvé ! Transporteur: ${meilleurTransporteur.prenom} ${meilleurTransporteur.nom} (à ~${Math.round(distanceMin)} km)`);
          
          // 2. Assigner la course
          await db.collection('courses').doc(courseId).update({
            transporteurId: meilleurTransporteur.id,
            nomTransporteur: `${meilleurTransporteur.prenom} ${meilleurTransporteur.nom}`,
            telephoneTransporteur: meilleurTransporteur.telephone || "",
            statut: 'acceptee', // Le statut passe à acceptée
          });

          // 3. Déclencher une notification Push via la collection que `worker_notifications.js` écoute
          await db.collection('notifications_push').add({
            titre: "🚚 Nouvelle course !",
            message: `Vous avez été assigné à une course de ${distanceMin.toFixed(1)}km. Récupérez le colis à ${course.adresseDepart}`,
            cible: "transporteurs", // Idéalement on ciblera spécifiquement ce transporteur par son FCM si implémenté dans le worker
            status: "pending",
            createdAt: new Date()
          });
          
          console.log(`Course ${courseId} assignée avec succès !`);

        } else {
          console.log(`❌ Aucun transporteur avec le véhicule adéquat (${course.typeVehicule}) n'est disponible.`);
        }

      } catch (err) {
        console.error(`❌ Erreur lors du dispatch pour ${courseId} :`, err);
      }
    }
  }, err => {
    console.error(`❌ Erreur d'écoute Firestore:`, err);
  });
