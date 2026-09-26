import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/services/service_authentification.dart';
import 'package:update_camtrans/modeles/message_chat.dart';

class EcranChat extends ConsumerStatefulWidget {
  final String courseId;

  const EcranChat({super.key, required this.courseId});

  @override
  ConsumerState<EcranChat> createState() => _EcranChatState();
}

class _EcranChatState extends ConsumerState<EcranChat> {
  final TextEditingController _controller = TextEditingController();

  void _envoyerMessage(String userId) async {
    final texte = _controller.text.trim();
    if (texte.isEmpty) return;

    _controller.clear();

    await FirebaseFirestore.instance
        .collection('courses')
        .doc(widget.courseId)
        .collection('messages')
        .add({
      'expediteurId': userId,
      'texte': texte,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(serviceAuthentificationProvider).utilisateur;
    final currentUserId = currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: CouleursApp.fondSombre,
      appBar: AppBar(
        backgroundColor: CouleursApp.fondSombreSecondaire,
        title: Text("Chat de la course", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('courses')
                  .doc(widget.courseId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: CouleursApp.primaire));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      "Aucun message pour l'instant.\nCommencez à discuter !",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: Colors.white54),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final msg = MessageChat.fromMap(data, docs[index].id);
                    final isMe = msg.expediteurId == currentUserId;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isMe ? CouleursApp.primaire : CouleursApp.fondSombreSecondaire,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMe ? 16 : 0),
                            bottomRight: Radius.circular(isMe ? 0 : 16),
                          ),
                        ),
                        child: Text(
                          msg.texte,
                          style: GoogleFonts.inter(color: Colors.white),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // Zone de saisie
          Container(
            padding: EdgeInsets.only(
              left: 16, right: 16, top: 12, 
              bottom: MediaQuery.of(context).padding.bottom + 12
            ),
            decoration: const BoxDecoration(
              color: CouleursApp.fondSombreSecondaire,
              border: Border(top: BorderSide(color: Colors.white12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Écrire un message...",
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: CouleursApp.fondSombre,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: CouleursApp.primaire,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: () => _envoyerMessage(currentUserId),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
