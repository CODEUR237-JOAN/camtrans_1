const { initializeApp, cert } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

const serviceAccount = require("./serviceAccountKey.json");

initializeApp({
  credential: cert(serviceAccount)
});

const db = getFirestore();

console.log("==================================================");
console.log("🚀 Serveur Backend Local CamTrans démarré !");
console.log("En écoute des événements Firestore...");
console.log("==================================================");

async function saveInAppNotification(utilisateurId, titre, message, type) {
  try {
    const docRef = db.collection('notifications').doc();
    await docRef.set({
      id: docRef.id,
      utilisateurId: utilisateurId,
      titre: titre,
      message: message,
      type: type,
      categorie: "Générale",
      lue: false,
      envoyee: true,
      dateCreation: new Date().toISOString(),
      dateLecture: null,
      image: "", lien: "", action: "",
      expediteurId: "ADMIN", expediteurNom: "Système CamTrans",
      priorite: "Normale",
      notificationPush: true, notificationEmail: false, notificationSms: false,
      donnees: {}
    });
  } catch (error) {
    console.error("Erreur saveInAppNotification:", error);
  }
}

// ============================================================================
// 1. Notification envoyée au Transporteur (Auto-Dispatch)
// ============================================================================
db.collection("courses").where("statut", "==", "recherche").onSnapshot(async (snapshot) => {
  for (const change of snapshot.docChanges()) {
    if (change.type === "added") {
      const courseData = change.doc.data();
      const courseId = change.doc.id;
      
      if (!courseData.transporteurId) {
        console.log(`[Auto-Dispatch] Lancement de l'attribution pour la course ${courseId}`);
        const latDepart = courseData.latitudeDepart || 0;
        const lngDepart = courseData.longitudeDepart || 0;
        const typeVehicule = courseData.typeVehicule || "";

        try {
          const transporteursSnapshot = await db.collection("transporteurs")
            .where("disponible", "==", true)
            .where("documentsValides", "==", true)
            .where("estEnLigne", "==", true)
            .get();

          const candidats = [];

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
            console.log(`[Auto-Dispatch] Aucun candidat trouvé pour la course ${courseId}`);
            continue;
          }

          candidats.sort((a, b) => a.distance - b.distance);

          const courseRef = db.collection("courses").doc(courseId);
          for (const candidat of candidats) {
            const transporteurRef = db.collection("transporteurs").doc(candidat.id);
            try {
              await db.runTransaction(async (transaction) => {
                const tSnap = await transaction.get(transporteurRef);
                const cSnap = await transaction.get(courseRef);
                if (!tSnap.exists || !cSnap.exists) throw new Error("Document manquant");
                if (cSnap.data().statut !== "recherche") throw new Error("Course plus en recherche");
                if (tSnap.data().disponible !== true || tSnap.data().estEnLigne !== true) {
                  throw new Error("Transporteur n'est plus disponible");
                }
                transaction.update(transporteurRef, { disponible: false });
                transaction.update(courseRef, {
                  transporteurId: candidat.id,
                  nomTransporteur: candidat.nom,
                  telephoneTransporteur: candidat.telephone,
                  statut: "attribue",
                  dateModification: FieldValue.serverTimestamp()
                });
              });
              console.log(`[Auto-Dispatch] Course ${courseId} attribuée à ${candidat.id}`);
              
                  const msgTitre = "Nouvelle course pour vous";
                  const msgBody = `Un client a besoin de vous pour aller vers ${courseData.adresseArrivee || "une destination"}. Ouvrez l'application pour accepter.`;
                  await saveInAppNotification(candidat.id, msgTitre, msgBody, "nouvelle_course");
                  
                  const tData = (await transporteurRef.get()).data();
                  if (tData && tData.fcmToken) {
                     await getMessaging().send({
                        token: tData.fcmToken,
                        notification: { title: msgTitre, body: msgBody },
                        android: { notification: { icon: '@mipmap/ic_launcher' } },
                        data: { courseId: courseId, type: "nouvelle_course" }
                     });
                  }
              break;
            } catch (err) {
              console.log(`[Auto-Dispatch] Collision pour ${candidat.id} : ${err.message}`);
            }
          }
        } catch (error) {
          console.error("Erreur Auto-Dispatch :", error);
        }
      }
    }
  }
});

// ============================================================================
// 2. Crédit automatique du portefeuille (Paiements)
// ============================================================================
db.collection("paiements").where("statut", "==", "succes").onSnapshot(async (snapshot) => {
  for (const change of snapshot.docChanges()) {
    if (change.type === "added") {
      const paiementData = change.doc.data();
      const paiementId = change.doc.id;

      if (paiementData.methodePaiement === "Espèces") continue;
      if (!paiementData.transporteurId) continue;
      if ((paiementData.courseId || "").startsWith('SUB-')) continue;
      if (paiementData.traiteParBackend === true) continue;

      const transporteurId = paiementData.transporteurId;
      const montantNet = (paiementData.montant || 0) * 0.98;

      try {
        const transporteurRef = db.collection("transporteurs").doc(transporteurId);
        await db.runTransaction(async (transaction) => {
          const doc = await transaction.get(transporteurRef);
          if (doc.exists) {
            transaction.update(transporteurRef, {
              soldePortefeuille: (doc.data().soldePortefeuille || 0) + montantNet
            });
          }
          transaction.update(db.collection("paiements").doc(paiementId), { traiteParBackend: true });
        });
        console.log(`[Paiement] Portefeuille de ${transporteurId} crédité de ${montantNet} FCFA.`);
      } catch (error) {
        console.error(`Erreur crédit portefeuille :`, error);
      }
    }
  }
});

// ============================================================================
// 3. Notification Client (Mise à jour statut)
// ============================================================================
db.collection("courses").onSnapshot(async (snapshot) => {
  for (const change of snapshot.docChanges()) {
    if (change.type === "modified") {
      const dataAfter = change.doc.data();
      const courseId = change.doc.id;

      if (dataAfter.statut === dataAfter.dernierStatutNotifie) continue;
      const clientId = dataAfter.clientId;
      if (!clientId) continue;

      try {
        const clientDoc = await db.collection("clients").doc(clientId).get();
        if (!clientDoc.exists) continue;

        const fcmToken = clientDoc.data().fcmToken;
        if (!fcmToken) continue;

        let titre = "Votre course avance";
        let message = "Il y a du nouveau sur votre course.";
        let send = false;

        switch (dataAfter.statut) {
          case "attribue":
            titre = "Votre chauffeur arrive";
            message = `${dataAfter.nomTransporteur || "Votre chauffeur"} a accepté votre course et se met en route.`;
            send = true; break;
          case "enRouteDepart":
            titre = "Votre chauffeur approche";
            message = "Il se dirige vers votre point de départ.";
            send = true; break;
          case "arriveDepart":
            titre = "Votre chauffeur est là";
            message = "Il vous attend au point de départ.";
            send = true; break;
          case "enTransit":
            titre = "C'est parti";
            message = "Votre chauffeur roule vers la destination.";
            send = true; break;
          case "terminee":
            titre = "Course terminée";
            message = "Tout s'est bien passé ? Merci de votre confiance !";
            send = true; break;
        }

        if (send) {
          await saveInAppNotification(clientId, titre, message, "mise_a_jour_statut");
          
          await getMessaging().send({
            token: fcmToken,
            notification: { title: titre, body: message },
            android: { notification: { icon: '@mipmap/ic_launcher' } },
            data: { courseId: courseId, type: "mise_a_jour_statut" }
          });
          await db.collection("courses").doc(courseId).update({ dernierStatutNotifie: dataAfter.statut });
          console.log(`[Notification] Statut mis à jour pour client ${clientId} (${dataAfter.statut})`);
        }
      } catch (error) {
        console.error("Erreur notification client :", error);
      }
    }
  }
});

// ============================================================================
// 4. Notifications Push Globales (Admin Panel)
// ============================================================================
db.collection("notifications_push").where("status", "==", "pending").onSnapshot(async (snapshot) => {
  for (const change of snapshot.docChanges()) {
    if (change.type === "added") {
      const data = change.doc.data();
      const notifRef = change.doc.ref;
      const { titre, message, cible, cibleId } = data;

      try {
        const usersToNotify = [];

        if ((cible === "client" || cible === "transporteur") && cibleId) {
          const col = cible === "client" ? "clients" : "transporteurs";
          const doc = await db.collection(col).doc(cibleId).get();
          if (doc.exists) usersToNotify.push({ id: doc.id, token: doc.data().fcmToken });
        } else {
          const collections = [];
          if (cible === "tous" || cible === "clients") collections.push("clients");
          if (cible === "tous" || cible === "transporteurs") collections.push("transporteurs");
          if (cible === "tous") collections.push("admin");

          for (const col of collections) {
            const snapCol = await db.collection(col).get();
            snapCol.forEach((doc) => {
              usersToNotify.push({ id: doc.id, token: doc.data().fcmToken });
            });
          }
        }

        if (usersToNotify.length === 0) {
          await notifRef.update({
            status: "envoye", totalDestinataires: 0, totalEnvoyes: 0, totalEchecs: 0,
            dateEnvoi: FieldValue.serverTimestamp(),
          });
          continue;
        }

        // 1. Sauvegarder dans Firestore pour l'interface In-App
        let batch = db.batch();
        let batchCount = 0;
        for (const user of usersToNotify) {
          const docRef = db.collection('notifications').doc();
          batch.set(docRef, {
            id: docRef.id,
            utilisateurId: user.id,
            titre: titre,
            message: message,
            type: data.type || "admin_broadcast",
            categorie: "Générale",
            lue: false,
            envoyee: true,
            dateCreation: new Date().toISOString(),
            dateLecture: null,
            image: "", lien: "", action: "",
            expediteurId: "ADMIN", expediteurNom: "Système CamTrans",
            priorite: "Normale",
            notificationPush: true, notificationEmail: false, notificationSms: false,
            donnees: {}
          });
          batchCount++;
          if (batchCount === 500) {
            await batch.commit();
            batch = db.batch();
            batchCount = 0;
          }
        }
        if (batchCount > 0) await batch.commit();

        // 2. Envoyer le Push Firebase
        const tokens = usersToNotify.map(u => u.token).filter(t => t != null && t !== "");
        
        let totalEnvoyes = 0;
        let totalEchecs = 0;
        for (let i = 0; i < tokens.length; i += 500) {
          const response = await getMessaging().sendEachForMulticast({
            tokens: tokens.slice(i, i + 500),
            notification: { title: titre, body: message },
            android: {
              notification: {
                icon: '@mipmap/ic_launcher'
              }
            },
            data: { type: data.type || "admin_broadcast" },
          });
          totalEnvoyes += response.successCount;
          totalEchecs += response.failureCount;
        }

        await notifRef.update({
          status: "envoye",
          totalDestinataires: tokens.length,
          totalEnvoyes: totalEnvoyes,
          totalEchecs: totalEchecs,
          dateEnvoi: FieldValue.serverTimestamp(),
        });
        console.log(`[Notification Globale] Envoyée avec succès : ${totalEnvoyes}/${tokens.length} reçues.`);
      } catch (error) {
        console.error("Erreur notification globale :", error);
        await notifRef.update({ status: "erreur", erreur: error.message });
      }
    }
  }
});

function getDistanceFromLatLonInKm(lat1, lon1, lat2, lon2) {
  const R = 6371; 
  const dLat = (lat2 - lat1) * (Math.PI / 180);
  const dLon = (lon2 - lon1) * (Math.PI / 180);
  const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
            Math.cos(lat1 * (Math.PI / 180)) * Math.cos(lat2 * (Math.PI / 180)) *
            Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}
