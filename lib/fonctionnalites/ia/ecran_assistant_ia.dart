import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../coeur/etat/ia_provider.dart';
import '../../coeur/constantes/couleurs.dart';
import '../../modeles/message_ia.dart';

class EcranAssistantIA extends ConsumerStatefulWidget {
  const EcranAssistantIA({super.key});

  @override
  ConsumerState<EcranAssistantIA> createState() => _EcranAssistantIAState();
}

class _EcranAssistantIAState extends ConsumerState<EcranAssistantIA> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<String> _cheminsImagesEnAttente = [];

  void _envoyerMessage() {
    final texte = _controller.text.trim();
    if (texte.isEmpty && _cheminsImagesEnAttente.isEmpty) return;

    ref.read(iaProvider.notifier).ajouterMessageUtilisateur(
      texte,
      cheminsImages: _cheminsImagesEnAttente,
    );

    _controller.clear();
    setState(() {
      _cheminsImagesEnAttente = [];
    });

    _faireDefilerEnBas();
  }

  void _faireDefilerEnBas() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _choisirImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _cheminsImagesEnAttente.add(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final iaState = ref.watch(iaProvider);

    // Faire défiler automatiquement quand de nouveaux messages arrivent
    ref.listen(iaProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length || next.enReponse) {
        _faireDefilerEnBas();
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.magic_star_copy, color: CouleursApp.primaire),
            SizedBox(width: 8),
            Text("Assistant CamTrans", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              ref.read(iaProvider.notifier).effacerHistorique();
            },
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: iaState.messages.isEmpty
                ? _buildEcranVide()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    itemCount: iaState.messages.length,
                    itemBuilder: (context, index) {
                      final msg = iaState.messages[index];
                      return _buildBulleMessage(msg);
                    },
                  ),
          ),
          _buildZoneSaisie(iaState.enReponse),
        ],
      ),
    );
  }

  Widget _buildEcranVide() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: CouleursApp.primaire.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Iconsax.message_text_copy, size: 60, color: CouleursApp.primaire),
          ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 20),
          const Text(
            "Comment puis-je vous aider ?",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestion("Estimer un prix de livraison"),
                _buildSuggestion("Quel véhicule choisir ?"),
                _buildSuggestion("Conseils d'emballage"),
                _buildSuggestion("Estimer le volume de mes biens"),
              ],
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
          )
        ],
      ),
    );
  }

  Widget _buildSuggestion(String texte) {
    return GestureDetector(
      onTap: () {
        _controller.text = texte;
        _envoyerMessage();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(texte, style: const TextStyle(color: Colors.black87, fontSize: 13)),
      ),
    );
  }

  Widget _buildBulleMessage(MessageIA msg) {
    return Align(
      alignment: msg.estUtilisateur ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!msg.estUtilisateur) ...[
              const CircleAvatar(
                radius: 16,
                backgroundColor: CouleursApp.primaire,
                child: Icon(Iconsax.magic_star_copy, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: msg.estUtilisateur ? CouleursApp.primaire : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16).copyWith(
                    bottomRight: msg.estUtilisateur ? const Radius.circular(0) : const Radius.circular(16),
                    bottomLeft: !msg.estUtilisateur ? const Radius.circular(0) : const Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (msg.piecesJointes.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        children: msg.piecesJointes.map((chemin) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(File(chemin), width: 100, height: 100, fit: BoxFit.cover),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                    ],
                    msg.estEnChargement && msg.texte.isEmpty
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black54),
                          )
                        : Semantics(
                            label: msg.estUtilisateur ? "Votre message : ${msg.texte}" : "Message de l'assistant : ${msg.texte}",
                            child: Text(
                              msg.texte,
                              style: TextStyle(
                                color: msg.estUtilisateur ? Colors.white : Colors.black87,
                                fontSize: 15,
                                height: 1.4,
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildZoneSaisie(bool enReponse) {
    return Container(
      padding: const EdgeInsets.all(16).copyWith(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          if (_cheminsImagesEnAttente.isNotEmpty)
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _cheminsImagesEnAttente.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 8, top: 8),
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: FileImage(File(_cheminsImagesEnAttente[index])),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _cheminsImagesEnAttente.removeAt(index);
                            });
                          },
                          child: Container(
                            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(Icons.close, color: Colors.white, size: 14),
                          ),
                        ),
                      )
                    ],
                  );
                },
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Iconsax.add_square_copy, color: Colors.grey),
                onPressed: _choisirImage,
                tooltip: "Ajouter une image",
              ),
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _envoyerMessage(),
                    decoration: const InputDecoration(
                      hintText: "Écrivez un message...",
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (!enReponse)
                IconButton(
                  icon: const Icon(Iconsax.microphone_2_copy, color: Colors.grey),
                  tooltip: "Dicter au microphone",
                  onPressed: () {
                    // TODO: Implémenter dictée vocale
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bouton micro (à venir)")));
                  },
                ),
              Semantics(
                button: true,
                label: "Envoyer le message",
                child: GestureDetector(
                  onTap: enReponse ? null : _envoyerMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: enReponse ? Colors.grey : CouleursApp.primaire,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Iconsax.send_2_copy, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
