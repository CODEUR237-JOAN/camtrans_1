const admin = require("firebase-admin");
const { getDistanceFromLatLonInKm } = require("./utils");

const MAX_RADIUS_KM = 30.0;

async function runAutoDispatch(courseId, courseData) {
  console.log(`[Auto-Dispatch] Lancement pour la course ${courseId}`);

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
      // Le typeVehicule demandé doit correspondre au véhicule du transporteur (sauf s'il est 'Tous')
      if (typeVehicule && tVehicule !== typeVehicule && tVehicule !== "Tous") continue;

      const tLat = t.latitude || 0;
      const tLng = t.longitude || 0;

      let dist = 999.0;
      if (latDepart !== 0 && tLat !== 0) {
        dist = getDistanceFromLatLonInKm(latDepart, lngDepart, tLat, tLng);
      }

      if (dist <= MAX_RADIUS_KM) {
        candidats.push({
          id: doc.id,
          distance: dist,
          nom: `${t.prenom || ""} ${t.nom || ""}`.trim(),
          telephone: t.telephone || ""
        });
      }
    }

    if (candidats.length === 0) {
      console.log(`[Auto-Dispatch] Aucun candidat trouvé dans le rayon pour la course ${courseId}`);
      return;
    }

    // 3. Trier par distance (le plus proche en premier)
    candidats.sort((a, b) => a.distance - b.distance);

    // 4. Attribution avec TRANSACTION Firestore
    const courseRef = admin.firestore().collection("courses").doc(courseId);

    for (const candidat of candidats) {
      const transporteurRef = admin.firestore().collection("transporteurs").doc(candidat.id);

      try {
        await admin.firestore().runTransaction(async (transaction) => {
          // Lecture
          const tSnap = await transaction.get(transporteurRef);
          const cSnap = await transaction.get(courseRef);

          if (!tSnap.exists || !cSnap.exists) throw new Error("Document manquant");

          const cData = cSnap.data();
          if (cData.statut !== "recherche") throw new Error("La course n'est plus en recherche");

          const tData = tSnap.data();
          // Vérification absolue de la disponibilité au moment de la transaction
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

        console.log(`[Auto-Dispatch] Course ${courseId} attribuée avec succès au transporteur ${candidat.id} (Distance: ${candidat.distance.toFixed(2)} km)`);
        // Match réussi, on arrête la boucle
        return;
      } catch (err) {
        console.log(`[Auto-Dispatch] Collision pour le candidat ${candidat.id} : ${err.message}. Essai du candidat suivant...`);
        // On continue la boucle pour essayer le prochain candidat
      }
    }

    console.log(`[Auto-Dispatch] Échec de l'attribution pour la course ${courseId} (aucun candidat n'a pu être verrouillé).`);

  } catch (error) {
    console.error(`[Auto-Dispatch] Erreur générale :`, error);
  }
}

module.exports = {
  runAutoDispatch
};
