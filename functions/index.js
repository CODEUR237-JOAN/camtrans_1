const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// ============================================================================
// Notification envoyee au Transporteur quand une nouvelle course lui est proposee
// ============================================================================
exports.onCourseCreated = functions.firestore
  .document("courses/{courseId}")
  .onCreate(async (snap, context) => {
    const courseData = snap.data();
    const transporteurId = courseData.transporteurCibleId || courseData.transporteurId;
    
    if (!transporteurId) {
      console.log("Aucun transporteur assigne a cette course.");
      return null;
    }

    try {
      const transporteurDoc = await admin.firestore().collection("transporteurs").doc(transporteurId).get();
      if (!transporteurDoc.exists) return null;

      const fcmToken = transporteurDoc.data().fcmToken;
      if (!fcmToken) {
        console.log(`Pas de token FCM pour le transporteur ${transporteurId}`);
        return null;
      }

      const payload = {
        notification: {
          title: "Nouvelle Course !",
          body: `Une nouvelle course vers ${courseData.adresseArrivee || "une destination"} vous a ete assignee.`,
        },
        data: {
          courseId: context.params.courseId,
          type: "nouvelle_course"
        }
      };

      await admin.messaging().sendToDevice(fcmToken, payload);
      console.log(`Notification envoyee au transporteur ${transporteurId}`);
      return null;
    } catch (error) {
      console.error("Erreur lors de l'envoi de la notification :", error);
      return null;
    }
  });

// ============================================================================
// Notification envoyee au Client quand le statut de la course change
// ============================================================================
exports.onCourseUpdated = functions.firestore
  .document("courses/{courseId}")
  .onUpdate(async (change, context) => {
    const dataBefore = change.before.data();
    const dataAfter = change.after.data();

    if (dataBefore.statut === dataAfter.statut) {
      return null;
    }

    const clientId = dataAfter.clientId;
    if (!clientId) return null;

    try {
      const clientDoc = await admin.firestore().collection("clients").doc(clientId).get();
      if (!clientDoc.exists) return null;

      const fcmToken = clientDoc.data().fcmToken;
      if (!fcmToken) {
        console.log(`Pas de token FCM pour le client ${clientId}`);
        return null;
      }

      let titre = "Mise a jour de votre course";
      let message = "Le statut de votre course a change.";

      switch (dataAfter.statut) {
        case "attribue":
          titre = "Chauffeur en route !";
          message = `Le chauffeur ${dataAfter.nomTransporteur || ""} a accepte votre course et est en route.`;
          break;
        case "enRouteDepart":
          titre = "Approche imminente";
          message = "Le chauffeur est en direction de votre point de depart.";
          break;
        case "arriveDepart":
          titre = "Le chauffeur est la !";
          message = "Votre chauffeur vous attend au point de depart.";
          break;
        case "enTransit":
          titre = "En transit";
          message = "Votre chauffeur est en route vers la destination.";
          break;
        case "termine":
          titre = "Course terminee";
          message = "Votre course s'est terminee avec succes ! Merci.";
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
      console.log(`Notification envoyee au client ${clientId} (Nouveau statut: ${dataAfter.statut})`);
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
  .document("courses/{courseId}")
  .onWrite(async (change, context) => {
    if (!change.after.exists) return null;

    const courseData = change.after.data();
    
    if (courseData.statut !== "recherche") return null;
    if (courseData.transporteurId && courseData.transporteurId !== "") return null;

    console.log(`Lancement de l'attribution pour la course ${context.params.courseId}`);

    const latDepart = courseData.latitudeDepart || 0;
    const lngDepart = courseData.longitudeDepart || 0;
    const typeVehicule = courseData.typeVehicule || "";
    const transporteursDeclines = courseData.transporteursDeclines || [];

    try {
      const transporteursSnapshot = await admin.firestore().collection("transporteurs")
        .where("disponible", "==", true)
        .where("documentsValides", "==", true)
        .get();

      let nextChauffeurId = "";
      let nextNom = "";
      let nextTel = "";
      let minDuration = Infinity;

      for (const doc of transporteursSnapshot.docs) {
        if (transporteursDeclines.includes(doc.id)) continue;
        const t = doc.data();

        const tVehicule = t.typeVehicule || "";
        if (typeVehicule && tVehicule !== typeVehicule && tVehicule !== "Tous") continue;

        const tLat = t.latitude || 0;
        const tLng = t.longitude || 0;

        if (latDepart !== 0 && tLat !== 0) {
          try {
            const url = `http://router.project-osrm.org/route/v1/driving/${tLng},${tLat};${lngDepart},${latDepart}?overview=false`;
            const response = await fetch(url);
            if (response.ok) {
              const data = await response.json();
              if (data.routes && data.routes.length > 0) {
                const duration = data.routes[0].duration;
                if (duration < minDuration) {
                  minDuration = duration;
                  nextChauffeurId = doc.id;
                  nextNom = `${t.prenom || ""} ${t.nom || ""}`.trim();
                  nextTel = t.telephone || "";
                }
              }
            }
          } catch(e) {
            console.error("Erreur OSRM", e);
          }
        }
      }

      if (nextChauffeurId !== "") {
        console.log(`Course ${context.params.courseId} attribuee a ${nextChauffeurId} (ETA: ${Math.round(minDuration/60)} min)`);
        await change.after.ref.update({
          transporteurId: nextChauffeurId,
          nomTransporteur: nextNom,
          telephoneTransporteur: nextTel,
          statut: "attribue"
        });
      } else {
        console.log(`Aucun chauffeur disponible pour la course ${context.params.courseId}`);
      }
    } catch (error) {
      console.error("Erreur lors de l'attribution :", error);
    }
    return null;
  });


// ============================================================================
// Notifications Push Globales — declenchees par l'Admin (collection notifications_push)
// ============================================================================
exports.envoyerNotificationGlobale = functions.firestore
  .document("notifications_push/{notifId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const { titre, message, cible } = data;

    if (!titre || !message) {
      console.log("Notification invalide : titre ou message manquant.");
      await snap.ref.update({ status: "erreur", erreur: "Champs titre/message manquants." });
      return null;
    }

    try {
      let tokens = [];

      const collections = [];
      if (cible === "tous") {
        collections.push("clients", "transporteurs");
      } else if (cible === "clients") {
        collections.push("clients");
      } else if (cible === "transporteurs") {
        collections.push("transporteurs");
      }

      for (const col of collections) {
        const snapshot = await admin.firestore().collection(col).get();
        snapshot.forEach(doc => {
          const token = doc.data().fcmToken;
          if (token) tokens.push(token);
        });
      }

      if (tokens.length === 0) {
        console.log("Aucun token FCM trouve pour la cible : " + cible);
        await snap.ref.update({ status: "erreur", erreur: "Aucun token trouve." });
        return null;
      }

      // Envoyer en lots de 500 (limite FCM)
      const chunks = [];
      for (let i = 0; i < tokens.length; i += 500) {
        chunks.push(tokens.slice(i, i + 500));
      }

      let totalEnvoyes = 0;
      for (const chunk of chunks) {
        const response = await admin.messaging().sendEachForMulticast({
          tokens: chunk,
          notification: { title: titre, body: message },
          data: { type: "admin_broadcast" },
        });
        totalEnvoyes += response.successCount;
        console.log(`Lot envoye : ${response.successCount} succes, ${response.failureCount} echecs.`);
      }

      await snap.ref.update({
        status: "envoye",
        totalDestinataires: tokens.length,
        totalEnvoyes: totalEnvoyes,
        dateEnvoi: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`Notification globale envoyee a ${totalEnvoyes}/${tokens.length} utilisateurs.`);
      return null;

    } catch (error) {
      console.error("Erreur envoi notification globale :", error);
      await snap.ref.update({ status: "erreur", erreur: error.message });
      return null;
    }
  });
