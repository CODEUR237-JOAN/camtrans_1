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
        token: fcmToken,
        notification: {
          title: "Nouvelle course pour vous",
          body: `Un client a besoin de vous pour aller vers ${courseData.adresseArrivee || "une destination"}. Ouvrez l'application pour accepter.`,
        },
        data: {
          courseId: context.params.courseId,
          type: "nouvelle_course"
        }
      };

      // API FCM HTTP v1 (l'ancienne API sendToDevice a été arrêtée par Google)
      await admin.messaging().send(payload);
      console.log(`Notification envoyee au transporteur ${transporteurId}`);
      return null;
    } catch (error) {
      console.error("Erreur lors de l'envoi de la notification :", error);
      return null;
    }
  });

// ============================================================================
// Credit automatique du portefeuille du transporteur a la creation d'un paiement digital
// ============================================================================
exports.crediterPortefeuille = functions.firestore
  .document("paiements/{paiementId}")
  .onCreate(async (snap, context) => {
    const paiementData = snap.data();

    // On ne traite que les paiements réussis et non en espèces
    if (paiementData.statut !== "succes") return null;
    if (paiementData.methodePaiement === "Espèces") return null;
    if (!paiementData.transporteurId) return null;
    if ((paiementData.courseId || "").startsWith('SUB-')) return null;

    const transporteurId = paiementData.transporteurId;
    const montant = paiementData.montant || 0;
    const montantNet = montant * 0.98; // 2% de frais plateforme

    try {
      const transporteurRef = admin.firestore().collection("transporteurs").doc(transporteurId);

      await admin.firestore().runTransaction(async (transaction) => {
        const doc = await transaction.get(transporteurRef);
        if (!doc.exists) {
          throw new Error("Transporteur introuvable !");
        }
        const soldeActuel = doc.data().soldePortefeuille || 0;
        transaction.update(transporteurRef, {
          soldePortefeuille: soldeActuel + montantNet
        });
      });
      console.log(`Portefeuille de ${transporteurId} crédité de ${montantNet} FCFA (Course: ${paiementData.courseId}).`);
      return null;
    } catch (error) {
      console.error(`Erreur lors du crédit du portefeuille pour ${transporteurId} :`, error);
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

      let titre = "Votre course avance";
      let message = "Il y a du nouveau sur votre course.";

      switch (dataAfter.statut) {
        case "attribue":
          titre = "Votre chauffeur arrive";
          message = `${dataAfter.nomTransporteur || "Votre chauffeur"} a accepté votre course et se met en route.`;
          break;
        case "enRouteDepart":
          titre = "Votre chauffeur approche";
          message = "Il se dirige vers votre point de départ.";
          break;
        case "arriveDepart":
          titre = "Votre chauffeur est là";
          message = "Il vous attend au point de départ.";
          break;
        case "enTransit":
          titre = "C'est parti";
          message = "Votre chauffeur roule vers la destination.";
          break;
        case "terminee":
          titre = "Course terminée";
          message = "Tout s'est bien passé ? Merci de votre confiance !";
          break;
      }

      const payload = {
        token: fcmToken,
        notification: {
          title: titre,
          body: message,
        },
        data: {
          courseId: context.params.courseId,
          type: "mise_a_jour_statut"
        }
      };

      await admin.messaging().send(payload);
      console.log(`Notification envoyee au client ${clientId} (Nouveau statut: ${dataAfter.statut})`);
      return null;
    } catch (error) {
      console.error("Erreur lors de l'envoi de la notification client :", error);
      return null;
    }
  });

// Calcule la distance entre deux coordonnees GPS en km (Formule de Haversine)
function getDistanceFromLatLonInKm(lat1, lon1, lat2, lon2) {
  const R = 6371; // Rayon de la terre en km
  const dLat = deg2rad(lat2 - lat1);
  const dLon = deg2rad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(deg2rad(lat1)) * Math.cos(deg2rad(lat2)) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  const d = R * c;
  return d;
}

function deg2rad(deg) {
  return deg * (Math.PI / 180);
}

// ============================================================================
// Attribution Automatique (Auto-Dispatch) Sécurisée
// ============================================================================
exports.processusAttribution = functions.firestore
  .document("courses/{courseId}")
  .onWrite(async (change, context) => {
    if (!change.after.exists) return null;

    const courseData = change.after.data();
    
    // On ne traite que si c'est en recherche et non attribué
    if (courseData.statut !== "recherche") return null;
    if (courseData.transporteurId && courseData.transporteurId !== "") return null;

    console.log(`[Auto-Dispatch] Lancement de l'attribution pour la course ${context.params.courseId}`);

    const latDepart = courseData.latitudeDepart || 0;
    const lngDepart = courseData.longitudeDepart || 0;
    const typeVehicule = courseData.typeVehicule || "";

    try {
      // 1. Récupérer les transporteurs en ligne et libres
      const transporteursSnapshot = await admin.firestore().collection("transporteurs")
        .where("disponible", "==", true)
        .where("documentsValides", "==", true)
        .where("estEnLigne", "==", true)
        .get();

      const candidats = [];

      // 2. Filtrage par type de véhicule et distance
      for (const doc of transporteursSnapshot.docs) {
        const t = doc.data();

        const tVehicule = t.typeVehicule || "";
        if (typeVehicule && tVehicule !== typeVehicule && tVehicule !== "Tous") continue;

        const tLat = t.latitude || 0;
        const tLng = t.longitude || 0;

        let dist = 999.0;
        if (latDepart !== 0 && tLat !== 0) {
          dist = getDistanceFromLatLonInKm(latDepart, lngDepart, tLat, tLng);
        }

        // Rayon de recherche de 30 km max
        if (dist <= 30.0) {
          candidats.push({
            id: doc.id,
            distance: dist,
            nom: `${t.prenom || ""} ${t.nom || ""}`.trim(),
            telephone: t.telephone || ""
          });
        }
      }

      if (candidats.length === 0) {
        console.log(`[Auto-Dispatch] Aucun candidat trouvé dans le rayon pour la course ${context.params.courseId}`);
        return null;
      }

      // 3. Trier par distance (le plus proche en premier)
      candidats.sort((a, b) => a.distance - b.distance);

      // 4. Attribution avec TRANSACTION Firestore
      const courseRef = change.after.ref;

      for (const candidat of candidats) {
        const transporteurRef = admin.firestore().collection("transporteurs").doc(candidat.id);

        try {
          await admin.firestore().runTransaction(async (transaction) => {
            // Lecture des deux documents (verrouillage)
            const tSnap = await transaction.get(transporteurRef);
            const cSnap = await transaction.get(courseRef);

            if (!tSnap.exists || !cSnap.exists) throw new Error("Document manquant");

            const cData = cSnap.data();
            if (cData.statut !== "recherche") throw new Error("La course n'est plus en recherche");

            const tData = tSnap.data();
            // Vérification absolue de la disponibilité au moment T
            if (tData.disponible !== true || tData.estEnLigne !== true) {
              throw new Error("Le transporteur n'est plus disponible");
            }

            // Écriture : verrouiller le transporteur et assigner la course
            transaction.update(transporteurRef, { disponible: false });
            transaction.update(courseRef, {
              transporteurId: candidat.id,
              nomTransporteur: candidat.nom,
              telephoneTransporteur: candidat.telephone,
              statut: "attribue",
              dateModification: admin.firestore.FieldValue.serverTimestamp()
            });
          });

          console.log(`[Auto-Dispatch] Course ${context.params.courseId} attribuée avec succès au transporteur ${candidat.id} (Distance: ${candidat.distance.toFixed(2)} km)`);
          // Match réussi, on arrête la boucle
          return null;
        } catch (err) {
          console.log(`[Auto-Dispatch] Collision pour le candidat ${candidat.id} : ${err.message}. Essai du suivant...`);
          // On continue la boucle pour essayer le prochain candidat
        }
      }

      console.log(`[Auto-Dispatch] Échec de l'attribution pour la course ${context.params.courseId} (aucun candidat n'a pu être verrouillé).`);

    } catch (error) {
      console.error("Erreur lors de l'attribution :", error);
    }
    return null;
  });

// ============================================================================
// Notifications Push — file d'attente `notifications_push`
// ============================================================================
exports.envoyerNotificationGlobale = functions.firestore
  .document("notifications_push/{notifId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const { titre, message, cible, cibleId } = data;

    // Idempotence : on ne traite que les demandes en attente. Les anciens
    // documents d'historique (déjà "envoye") ne sont jamais ré-expédiés.
    if ((data.status || "pending") !== "pending") return null;

    if (!titre || !message) {
      await snap.ref.update({ status: "erreur", erreur: "Il manque le titre ou le message." });
      return null;
    }

    try {
      const tokens = [];

      if ((cible === "client" || cible === "transporteur") && cibleId) {
        // Envoi ciblé vers une seule personne
        const col = cible === "client" ? "clients" : "transporteurs";
        const doc = await admin.firestore().collection(col).doc(cibleId).get();
        const token = doc.exists ? doc.data().fcmToken : null;
        if (token) tokens.push(token);
      } else {
        // Diffusion
        const collections = [];
        if (cible === "tous" || cible === "clients") collections.push("clients");
        if (cible === "tous" || cible === "transporteurs") collections.push("transporteurs");
        if (cible === "tous") collections.push("admin");

        for (const col of collections) {
          const snapshot = await admin.firestore().collection(col).get();
          snapshot.forEach((doc) => {
            const token = doc.data().fcmToken;
            if (token) tokens.push(token);
          });
        }
      }

      if (tokens.length === 0) {
        await snap.ref.update({
          status: "envoye",
          totalDestinataires: 0,
          totalEnvoyes: 0,
          totalEchecs: 0,
          dateEnvoi: admin.firestore.FieldValue.serverTimestamp(),
        });
        return null;
      }

      // Envoi par lots de 500 (limite FCM)
      let totalEnvoyes = 0;
      let totalEchecs = 0;
      for (let i = 0; i < tokens.length; i += 500) {
        const response = await admin.messaging().sendEachForMulticast({
          tokens: tokens.slice(i, i + 500),
          notification: { title: titre, body: message },
          data: { type: data.type || "admin_broadcast" },
        });
        totalEnvoyes += response.successCount;
        totalEchecs += response.failureCount;
      }

      await snap.ref.update({
        status: "envoye",
        totalDestinataires: tokens.length,
        totalEnvoyes: totalEnvoyes,
        totalEchecs: totalEchecs,
        dateEnvoi: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`Notification ${context.params.notifId} : ${totalEnvoyes}/${tokens.length} envoyée(s).`);
      return null;
    } catch (error) {
      console.error("Erreur envoi notification :", error);
      await snap.ref.update({ status: "erreur", erreur: error.message });
      return null;
    }
  });
