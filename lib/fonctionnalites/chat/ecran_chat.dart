import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/services/service_authentification.dart';
import 'package:update_camtrans/services/service_stockage.dart';
import 'package:update_camtrans/modeles/message_chat.dart';

class EcranChat extends ConsumerStatefulWidget {
  final String courseId;

  const EcranChat({super.key, required this.courseId});

  @override
  ConsumerState<EcranChat> createState() => _EcranChatState();
}

class _EcranChatState extends ConsumerState<EcranChat> {
  final TextEditingController _controller = TextEditingController();
  bool _envoiImageEnCours = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  CollectionReference<Map<String, dynamic>> get _messagesRef =>
      FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .collection('messages');

  void _envoyerMessage(String userId) async {
    final texte = _controller.text.trim();
    if (texte.isEmpty) return;

    _controller.clear();

    await _messagesRef.add({
      'expediteurId': userId,
      'texte': texte,
      'imageUrl': '',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // -----------------------------------------------------------------
  // Choix de la source (galerie / appareil photo) puis envoi d'image
  // -----------------------------------------------------------------
  Future<void> _choisirSourceImage(String userId) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: CouleursApp.fondSombreSecondaire,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: CouleursApp.primaire),
              title: Text('Galerie',
                  style: GoogleFonts.inter(color: Colors.white)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: CouleursApp.primaire),
              title: Text('Appareil photo',
                  style: GoogleFonts.inter(color: Colors.white)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;
    await _envoyerImage(userId, source);
  }

  Future<void> _envoyerImage(String userId, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? fichier = await picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1600,
      );
      if (fichier == null) return;

      setState(() => _envoiImageEnCours = true);

      final url = await ref.read(serviceStockageProvider).uploaderFichier(
            fichier: fichier,
            dossier: 'chat/${widget.courseId}',
            nomFichier: '${userId}_${DateTime.now().millisecondsSinceEpoch}',
          );

      if (url == null) {
        throw Exception('le serveur d\'images n\'a pas répondu');
      }

      await _messagesRef.add({
        'expediteurId': userId,
        'texte': '',
        'imageUrl': url,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Impossible d\'envoyer l\'image ($e).'),
          backgroundColor: CouleursApp.erreur,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _envoiImageEnCours = false);
    }
  }

  void _ouvrirImagePleinEcran(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                placeholder: (c, u) => const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                      child: CircularProgressIndicator(
                          color: CouleursApp.primaire)),
                ),
                errorWidget: (c, u, e) => const Padding(
                  padding: EdgeInsets.all(40),
                  child: Icon(Icons.broken_image, color: Colors.white54),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(serviceAuthentificationProvider).utilisateur;
    final currentUserId = currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: CouleursApp.fondSombre,
      appBar: AppBar(
        backgroundColor: CouleursApp.fondSombreSecondaire,
        title: Text("Chat de la course",
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _messagesRef
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: CouleursApp.primaire));
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
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: msg.estImage
                            ? const EdgeInsets.all(5)
                            : const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isMe
                              ? CouleursApp.primaire
                              : CouleursApp.fondSombreSecondaire,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMe ? 16 : 0),
                            bottomRight: Radius.circular(isMe ? 0 : 16),
                          ),
                        ),
                        child: _contenuMessage(msg),
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
                left: 8,
                right: 16,
                top: 12,
                bottom: MediaQuery.of(context).padding.bottom + 12),
            decoration: const BoxDecoration(
              color: CouleursApp.fondSombreSecondaire,
              border: Border(top: BorderSide(color: Colors.white12)),
            ),
            child: Row(
              children: [
                // Bouton pièce jointe (image)
                IconButton(
                  tooltip: "Envoyer une image",
                  icon: _envoiImageEnCours
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: CouleursApp.primaire),
                        )
                      : const Icon(Icons.add_photo_alternate_outlined,
                          color: CouleursApp.primaire),
                  onPressed: _envoiImageEnCours
                      ? null
                      : () => _choisirSourceImage(currentUserId),
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _envoyerMessage(currentUserId),
                    decoration: InputDecoration(
                      hintText: "Écrire un message...",
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: CouleursApp.fondSombre,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
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

  // Contenu d'une bulle : image (avec légende éventuelle) ou texte simple.
  Widget _contenuMessage(MessageChat msg) {
    if (!msg.estImage) {
      return Text(msg.texte, style: GoogleFonts.inter(color: Colors.white));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _ouvrirImagePleinEcran(msg.imageUrl),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: msg.imageUrl,
              width: 220,
              fit: BoxFit.cover,
              placeholder: (c, u) => Container(
                width: 220,
                height: 220,
                color: Colors.black26,
                child: const Center(
                    child: CircularProgressIndicator(
                        color: CouleursApp.primaire)),
              ),
              errorWidget: (c, u, e) => Container(
                width: 220,
                height: 160,
                color: Colors.black26,
                child: const Icon(Icons.broken_image, color: Colors.white54),
              ),
            ),
          ),
        ),
        if (msg.texte.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4, right: 4, bottom: 2),
            child: Text(msg.texte,
                style: GoogleFonts.inter(color: Colors.white)),
          ),
      ],
    );
  }
}
