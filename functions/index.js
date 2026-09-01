const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// ============================================================================
// Notification envoyée au Transporteur quand une nouvelle course lui est proposée
// ============================================================================
exports.onCourseCreated = functions.firestore
  .document("courses/{courseId}")
  .onCreate(async (snap, context) => {
    const courseData = snap.data();
    const transporteurId = courseData.transporteurCibleId || courseData.transporteurId;
    
    if (!transporteurId) {
      console.log("Aucun transporteur assigné à cette course.");
      return null;
    }

    try {
      // Récupérer les infos du transporteur pour avoir son Token FCM
      const transporteurDoc = await admin.firestore().collection("transporteurs").doc(transporteurId).get();
      if (!transporteurDoc.exists) return null;

      const fcmToken = transporteurDoc.data().fcmToken;
      if (!fcmToken) {
        console.log(`Pas de token FCM pour le transporteur ${transporteurId}`);
        return null;
      }

      // Construire le message Push
      const payload = {
        notification: {
          title: "Nouvelle Course !",
          body: `Une nouvelle course vers ${courseData.adresseArrivee || "une destination"} vous a été assignée.`,
        },
        data: {
          courseId: context.params.courseId,
          type: "nouvelle_course"
        }
      };

      // Envoyer via FCM
      await admin.messaging().sendToDevice(fcmToken, payload);
      console.log(`Notification envoyée au transporteur ${transporteurId}`);
      return null;
    } catch (error) {
      console.error("Erreur lors de l'envoi de la notification :", error);
      return null;
    }
  });

// ============================================================================
// Notification envoyée au Client quand le statut de la course change
// ============================================================================
exports.onCourseUpdated = functions.firestore
  .document("courses/{courseId}")
  .onUpdate(async (change, context) => {
    const dataBefore = change.before.data();
    const dataAfter = change.after.data();

    // On ne notifie que si le statut a changé
    if (dataBefore.statut === dataAfter.statut) {
      return null;
    }

    const clientId = dataAfter.clientId;
    if (!clientId) return null;

    try {
      // Récupérer le token du client
      const clientDoc = await admin.firestore().collection("clients").doc(clientId).get();
      if (!clientDoc.exists) return null;

      const fcmToken = clientDoc.data().fcmToken;
      if (!fcmToken) {
        console.log(`Pas de token FCM pour le client ${clientId}`);
        return null;
      }

      let titre = "Mise à jour de votre course";
      let message = `Le statut de votre course a changé.`;

      // Personnaliser le message selon le nouveau statut
      switch (dataAfter.statut) {
        case "attribue":
          titre = "Chauffeur en route !";
          message = `Le chauffeur ${dataAfter.nomTransporteur || ""} a accepté votre course et est en route.`;
          break;
        case "enRouteDepart":
          titre = "Approche imminente";
          message = `Le chauffeur est en direction de votre point de départ.`;
          break;
        case "arriveDepart":
          titre = "Le chauffeur est là !";
          message = `Votre chauffeur vous attend au point de départ.`;
          break;
        case "enTransit":
          titre = "En transit";
          message = `Vos biens sont en route vers la destination.`;
          break;
        case "termine":
          titre = "Course terminée";
          message = `Votre course a été livrée avec succès ! Merci.`;
          break;
      }

      const payload = {
        notification: {
          title: titre,
          body: message,
        },
        data: {
          courseId: context.params.courseId,
          type: "mise_a_jour_statut"
        }
      };

      await admin.messaging().sendToDevice(fcmToken, payload);
      console.log(`Notification envoyée au client ${clientId} (Nouveau statut: ${dataAfter.statut})`);
      return null;
    } catch (error) {
      console.error("Erreur lors de l'envoi de la notification client :", error);
      return null;
    }
  });


// ============================================================================
// Attribution Automatique avec algorithme en cascade (OSRM)
// ============================================================================
exports.processusAttribution = functions.firestore
  .document('courses/{courseId}')
  .onWrite(async (change, context) => {
    if (!change.after.exists) return null; // Suppression

    const courseData = change.after.data();
    
    // Uniquement quand la course est en 'recherche'
    if (courseData.statut !== 'recherche') return null;

    // �viter les boucles si on vient de lui attribuer
    if (courseData.transporteurId && courseData.transporteurId !== '') return null;

    console.log(\Lancement de l'attribution pour la course \\);

    const latDepart = courseData.latitudeDepart || 0;
    const lngDepart = courseData.longitudeDepart || 0;
    const typeVehicule = courseData.typeVehicule || '';
    const transporteursDeclines = courseData.transporteursDeclines || [];

    try {
      const transporteursSnapshot = await admin.firestore().collection('transporteurs')
        .where('disponible', '==', true)
        .where('documentsValides', '==', true)
        .get();

      let nextChauffeurId = '';
      let nextNom = '';
      let nextTel = '';
      let minDuration = Infinity;

      for (const doc of transporteursSnapshot.docs) {
        if (transporteursDeclines.includes(doc.id)) continue;
        const t = doc.data();

        const tVehicule = t.typeVehicule || '';
        if (typeVehicule && tVehicule !== typeVehicule && tVehicule !== 'Tous') continue;

        const tLat = t.latitude || 0;
        const tLng = t.longitude || 0;

        if (latDepart !== 0 && tLat !== 0) {
           try {
              const url = \http://router.project-osrm.org/route/v1/driving/\,\;\,\?overview=false\;
              const response = await fetch(url);
              if (response.ok) {
                 const data = await response.json();
                 if (data.routes && data.routes.length > 0) {
                    const duration = data.routes[0].duration; // en secondes
                    if (duration < minDuration) {
                       minDuration = duration;
                       nextChauffeurId = doc.id;
                       nextNom = \\ \\;
                       nextTel = t.telephone || '';
                    }
                 }
              }
           } catch(e) {
              console.error('Erreur OSRM', e);
           }
        }
      }

      if (nextChauffeurId !== '') {
        console.log(\Course \ attribu�e � \ (ETA: \ min)\);
        await change.after.ref.update({
          transporteurId: nextChauffeurId,
          nomTransporteur: nextNom,
          telephoneTransporteur: nextTel,
          statut: 'attribue'
        });
      } else {
        console.log(\Aucun chauffeur disponible pour la course \\);
      }
    } catch (error) {
      console.error('Erreur lors de attribution :', error);
    }
    return null;
  });

