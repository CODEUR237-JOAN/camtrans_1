import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/widgets/effets_visuels.dart';

class PageAssistants extends StatefulWidget {
  const PageAssistants({super.key});

  @override
  State<PageAssistants> createState() => _PageAssistantsState();
}

class _PageAssistantsState extends State<PageAssistants> {
  final _emailController = TextEditingController();
  final _nomController = TextEditingController();
  bool _chargement = false;

  Future<void> _ajouterAssistant() async {
    final email = _emailController.text.trim();
    final nom = _nomController.text.trim();
    if (email.isEmpty || nom.isEmpty) return;

    setState(() => _chargement = true);
    try {
      final docRef = FirebaseFirestore.instance.collection('admin').doc();
      await docRef.set({
        'email': email,
        'nom': nom,
        'role': 'assistant',
        'dateCreation': FieldValue.serverTimestamp(),
      });
      _emailController.clear();
      _nomController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compte assistant créé avec succès !')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      setState(() => _chargement = false);
    }
  }

  Future<void> _supprimerAssistant(String id) async {
    await FirebaseFirestore.instance.collection('admin').doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Comptes Assistants",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Gérez les accès de vos collaborateurs. Ils auront accès au Dashboard Administrateur.",
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 32),

          // Formulaire d'ajout
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nomController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Nom de l\'assistant',
                        labelStyle: TextStyle(color: Colors.white54),
                        prefixIcon: Icon(Icons.person, color: Colors.white54),
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Adresse Email',
                        labelStyle: TextStyle(color: Colors.white54),
                        prefixIcon: Icon(Icons.email, color: Colors.white54),
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _chargement ? null : _ajouterAssistant,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CouleursApp.primaire,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                    ),
                    icon: _chargement
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.add, color: Colors.white),
                    label: const Text("Ajouter",
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Liste des assistants
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('admin')
                  .where('role', isEqualTo: 'assistant')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "Aucun assistant pour le moment.",
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return Card(
                      color: Colors.white.withValues(alpha: 0.05),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              CouleursApp.secondaire.withValues(alpha: 0.2),
                          child: const Icon(Icons.person,
                              color: CouleursApp.secondaire),
                        ),
                        title: Text(data['nom'] ?? 'Sans nom',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        subtitle: Text(data['email'] ?? '',
                            style: const TextStyle(color: Colors.white70)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete,
                              color: Colors.redAccent),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: const Color(0xFF1E293B),
                                title: const Text('Supprimer cet assistant ?',
                                    style: TextStyle(color: Colors.white)),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Annuler',
                                        style:
                                            TextStyle(color: Colors.white54)),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      _supprimerAssistant(docs[index].id);
                                      Navigator.pop(ctx);
                                    },
                                    child: const Text('Supprimer',
                                        style: TextStyle(
                                            color: Colors.redAccent)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
