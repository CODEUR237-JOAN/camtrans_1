import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/modeles/transporteur.dart';
import 'package:update_camtrans/services/service_authentification.dart';
import 'package:update_camtrans/services/service_firestore.dart';
import 'package:update_camtrans/modeles/message.dart';

class EcranChat extends ConsumerStatefulWidget {
  final Transporteur transporteur;
  
  const EcranChat({super.key, required this.transporteur});

  @override
  ConsumerState<EcranChat> createState() => _EcranChatState();
}

class _EcranChatState extends ConsumerState<EcranChat> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String get clientId => ref.read(authStateProvider).value?.uid ?? "anonyme";
  String get conversationId => "${clientId}_${widget.transporteur.id}";

  Future<void> _envoyerMessage() async {
    final texte = _messageController.text.trim();
    if (texte.isEmpty) return;
    
    _messageController.clear();

    final message = Message(
      id: '', // Généré par Firestore
      expediteurId: clientId,
      destinataireId: widget.transporteur.id,
      contenu: texte,
      dateEnvoi: DateTime.now(),
    );

    try {
      final data = message.versMap();
      data['conversationId'] = conversationId;
      await ref.read(serviceFirestoreProvider).envoyerMessage(data);
    } catch (e) {
      debugPrint("Erreur envoi message : $e");
    }
  }

  String _formatTime(DateTime date) {
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_2_copy, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: CouleursApp.primaire.withValues(alpha: 0.1),
              backgroundImage: widget.transporteur.photo.isNotEmpty ? NetworkImage(widget.transporteur.photo) : null,
              child: widget.transporteur.photo.isEmpty ? const Icon(Icons.person, color: CouleursApp.primaire, size: 20) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${widget.transporteur.prenom} ${widget.transporteur.nom}",
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 4),
                      Text("En ligne", style: GoogleFonts.inter(fontSize: 12, color: Colors.green)),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.call_copy, color: CouleursApp.primaire),
            onPressed: () {
              // Action appel
            },
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder(
                stream: ref.watch(serviceFirestoreProvider).fluxMessages(conversationId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: CouleursApp.primaire));
                  }
                  
                  if (snapshot.hasError) {
                    return Center(child: Text("Erreur : ${snapshot.error}"));
                  }

                  final docs = snapshot.data?.docs ?? [];
                  // Tri explicite par date pour garantir l'ordre chronologique
                  final messages = docs
                      .map((doc) => Message.depuisMap(doc.data(), doc.id))
                      .toList()
                      ..sort((a, b) => b.dateEnvoi.compareTo(a.dateEnvoi)); // desc pour reverse:true

                  if (messages.isEmpty) {
                    return Center(
                      child: Text(
                        "Dites bonjour à ${widget.transporteur.prenom} !",
                        style: GoogleFonts.inter(color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true, // Affiche les messages du bas vers le haut
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isUser = msg.expediteurId == clientId;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!isUser) ...[
                              CircleAvatar(
                                radius: 14,
                                backgroundImage: widget.transporteur.photo.isNotEmpty ? NetworkImage(widget.transporteur.photo) : null,
                                child: widget.transporteur.photo.isEmpty ? const Icon(Icons.person, size: 14) : null,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                decoration: BoxDecoration(
                                  color: isUser ? CouleursApp.primaire : Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(20),
                                    topRight: const Radius.circular(20),
                                    bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
                                    bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
                                  ),
                                  boxShadow: [
                                    if (!isUser) BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
                                  ]
                                ),
                                child: Column(
                                  crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      msg.contenu,
                                      style: GoogleFonts.inter(
                                        color: isUser ? Colors.white : Colors.black87,
                                        fontSize: 15,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatTime(msg.dateEnvoi),
                                      style: GoogleFonts.inter(
                                        color: isUser ? Colors.white.withValues(alpha: 0.7) : Colors.black45,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (isUser) const SizedBox(width: 30),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            
            // Input Area
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      // Action pièce jointe
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fonctionnalité d'envoi d'images à venir.")));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Iconsax.camera_copy, color: Colors.grey, size: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: GoogleFonts.inter(fontSize: 15),
                        decoration: InputDecoration(
                          hintText: "Écrire un message...",
                          hintStyle: GoogleFonts.inter(color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                        onSubmitted: (_) => _envoyerMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _envoyerMessage();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        color: CouleursApp.primaire,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Iconsax.send_2_copy, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
