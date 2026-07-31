import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:flutter_markdown/flutter_markdown.dart';
import '../../coeur/etat/ia_provider.dart';
import '../../coeur/constantes/couleurs.dart';
import '../../modeles/message_ia.dart';
import '../../coeur/widgets/page_responsive.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Faire défiler automatiquement quand de nouveaux messages arrivent
    ref.listen(iaProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length || next.enReponse) {
        _faireDefilerEnBas();
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Iconsax.magic_star_copy, color: CouleursApp.primaire),
            const SizedBox(width: 8),
            Text("Assistant CamTrans", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        iconTheme: IconThemeData(color: Theme.of(context).textTheme.bodyLarge?.color),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              ref.read(iaProvider.notifier).effacerHistorique();
            },
          )
        ],
      ),
      body: PageResponsive(
        child: Column(
          children: [
            Expanded(
              child: iaState.messages.isEmpty
                  ? _buildEcranVide(isDark)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      itemCount: iaState.messages.length,
                      itemBuilder: (context, index) {
                        final msg = iaState.messages[index];
                        return _buildBulleMessage(msg, isDark);
                      },
                    ),
            ),
            _buildZoneSaisie(iaState.enReponse, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildEcranVide(bool isDark) {
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
          Text(
            "Comment puis-je vous aider ?",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestion("Estimer un prix de livraison", isDark),
                _buildSuggestion("Quel véhicule choisir ?", isDark),
                _buildSuggestion("Conseils d'emballage", isDark),
                _buildSuggestion("Estimer le volume de mes biens", isDark),
              ],
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
          )
        ],
      ),
    );
  }

  Widget _buildSuggestion(String texte, bool isDark) {
    return GestureDetector(
      onTap: () {
        _controller.text = texte;
        _envoyerMessage();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? Theme.of(context).cardColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
        ),
        child: Text(texte, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 13)),
      ),
    );
  }

  Widget _buildBulleMessage(MessageIA msg, bool isDark) {
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
                  color: msg.estUtilisateur ? CouleursApp.primaire : (isDark ? Theme.of(context).cardColor : Colors.grey.shade100),
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
                            child: msg.estUtilisateur
                                ? Text(
                                    msg.texte,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      height: 1.4,
                                    ),
                                  )
                                : MarkdownBody(
                                    data: msg.texte,
                                    styleSheet: MarkdownStyleSheet(
                                      p: TextStyle(fontSize: 15, height: 1.4, color: Theme.of(context).textTheme.bodyLarge?.color),
                                      listBullet: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
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

  Widget _buildZoneSaisie(bool enReponse, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16).copyWith(bottom: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
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
                    color: isDark ? Theme.of(context).cardColor : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _envoyerMessage(),
                    decoration: InputDecoration(
                      hintText: "Écrivez un message...",
                      hintStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
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
