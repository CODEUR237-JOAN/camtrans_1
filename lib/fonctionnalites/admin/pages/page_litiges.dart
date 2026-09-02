import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/constantes/statuts.dart';
import 'package:update_camtrans/coeur/etat/admin_provider.dart';
import 'package:update_camtrans/modeles/course.dart';
import 'package:update_camtrans/modeles/paiement.dart';
import 'package:update_camtrans/services/service_firestore.dart';
import 'package:update_camtrans/coeur/widgets/loader_premium.dart';

class PageLitiges extends ConsumerStatefulWidget {
  const PageLitiges({super.key});

  @override
  ConsumerState<PageLitiges> createState() => _PageLitigesState();
}

class _PageLitigesState extends ConsumerState<PageLitiges>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08111F),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== EN-TÊTE =====
          Container(
            padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.gavel, color: Colors.redAccent, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Supervision & Litiges',
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold)),
                        Text('Accès complet — Courses, Paiements, Messages',
                            style: TextStyle(color: Colors.white54, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ===== BARRE DE RECHERCHE =====
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Rechercher par ID, nom, téléphone...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.search, color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.06),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ===== ONGLETS =====
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.redAccent,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white38,
                  labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(text: '🚚 Courses'),
                    Tab(text: '💳 Paiements'),
                    Tab(text: '💬 Conversations'),
                  ],
                ),
              ],
            ),
          ),

          // ===== CONTENU =====
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _OngletCourses(searchQuery: _searchQuery),
                _OngletPaiements(searchQuery: _searchQuery),
                _OngletConversations(searchQuery: _searchQuery),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ONGLET COURSES
// ============================================================
class _OngletCourses extends ConsumerWidget {
  final String searchQuery;
  const _OngletCourses({required this.searchQuery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(adminCoursesProvider);

    return coursesAsync.when(
      loading: () => Center(child: LoaderPremium()),
      error: (e, _) => Center(child: Text('Erreur: $e', style: const TextStyle(color: Colors.red))),
      data: (courses) {
        final filtered = searchQuery.isEmpty
            ? courses
            : courses.where((c) =>
                c.id.toLowerCase().contains(searchQuery) ||
                c.nomClient.toLowerCase().contains(searchQuery) ||
                c.nomTransporteur.toLowerCase().contains(searchQuery) ||
                c.adresseDepart.toLowerCase().contains(searchQuery) ||
                c.adresseArrivee.toLowerCase().contains(searchQuery)).toList();

        if (filtered.isEmpty) {
          return const Center(
              child: Text('Aucune course correspondante, c\'est très calme par ici ! 🌴', style: TextStyle(color: Colors.white38)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: filtered.length,
          itemBuilder: (ctx, i) => _CarteCourse(course: filtered[i]),
        );
      },
    );
  }
}

class _CarteCourse extends ConsumerWidget {
  final Course course;
  const _CarteCourse({required this.course});

  Color _couleurStatut(String statut) {
    if (statut == StatutCourse.terminee) return Colors.green;
    if (statut == StatutCourse.annulee) return Colors.red;
    if (StatutCourse.estActive(statut)) return Colors.blue;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: ExpansionTile(
        collapsedIconColor: Colors.white54,
        iconColor: CouleursApp.primaire,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: _couleurStatut(course.statut).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6)),
              child: Text(StatutCourse.libelle(course.statut),
                  style: TextStyle(
                      color: _couleurStatut(course.statut),
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Course #${course.id.substring(0, 8).toUpperCase()}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        subtitle: Text(
          '${course.nomClient} → ${course.nomTransporteur.isEmpty ? "Non assigné" : course.nomTransporteur}',
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(color: Colors.white12),
                _infoRow(Icons.location_on, 'Départ', course.adresseDepart),
                _infoRow(Icons.flag, 'Arrivée', course.adresseArrivee),
                _infoRow(Icons.phone, 'Tél Client', course.telephoneClient),
                _infoRow(Icons.phone_android, 'Tél Transporteur',
                    course.telephoneTransporteur.isEmpty ? 'N/A' : course.telephoneTransporteur),
                _infoRow(Icons.monetization_on, 'Prix',
                    '${course.prixEstime.toInt()} FCFA estimé / ${course.prixFinal.toInt()} FCFA final'),
                _infoRow(Icons.calendar_today, 'Créée le',
                    DateFormat('dd/MM/yyyy HH:mm').format(course.dateCreation)),
                if (course.description.isNotEmpty)
                  _infoRow(Icons.notes, 'Description', course.description),
                const SizedBox(height: 12),

                // ACTIONS ADMIN
                Row(
                  children: [
                    if (course.statut != StatutCourse.annulee &&
                        course.statut != StatutCourse.terminee)
                      ElevatedButton.icon(
                        onPressed: () => _annulerCourse(context, ref, course),
                        icon: const Icon(Icons.cancel, size: 16),
                        label: const Text('Annuler la course'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white38, size: 16),
          const SizedBox(width: 8),
          Text('$label : ', style: const TextStyle(color: Colors.white38, fontSize: 13)),
          Expanded(
              child: Text(value,
                  style: const TextStyle(color: Colors.white70, fontSize: 13))),
        ],
      ),
    );
  }

  Future<void> _annulerCourse(BuildContext ctx, WidgetRef ref, Course course) async {
    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Annuler la course'),
        content: Text('Êtes-vous sûr de vouloir annuler la course #${course.id.substring(0, 8).toUpperCase()} ? Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Non')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Oui, annuler', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await ref.read(serviceFirestoreProvider).modifierDocument(
      collection: 'courses',
      id: course.id,
      donnees: {
        'statut': StatutCourse.annulee,
        'commentaireAdmin': 'Annulée par l\'administrateur suite à un litige.',
      },
    );

    // Notification aux deux parties
    final now = DateTime.now().toIso8601String();
    final db = ref.read(serviceFirestoreProvider);
    for (final uid in [course.clientId, if (course.transporteurId.isNotEmpty) course.transporteurId]) {
      await db.ajouterDocument(
        collection: 'notifications',
        id: 'NOTIF-LITIGE-${uid.substring(0, 5)}-${DateTime.now().millisecondsSinceEpoch}',
        donnees: {
          'utilisateurId': uid,
          'titre': '⚠️ Course annulée par l\'admin',
          'message': 'La course #${course.id.substring(0, 8).toUpperCase()} a été annulée suite à un litige.',
          'type': 'alerte',
          'categorie': 'litige',
          'lue': false,
          'envoyee': true,
          'dateCreation': now,
          'image': '',
          'lien': '',
          'action': '',
          'expediteurId': 'ADMIN',
          'expediteurNom': 'Administrateur CamTrans',
          'priorite': 'haute',
          'notificationPush': true,
          'notificationEmail': false,
          'notificationSms': false,
          'donnees': {},
        },
      );
    }

    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Course annulée. Les deux parties ont été notifiées.'), backgroundColor: Colors.green),
      );
    }
  }
}

// ============================================================
// ONGLET PAIEMENTS
// ============================================================
class _OngletPaiements extends ConsumerWidget {
  final String searchQuery;
  const _OngletPaiements({required this.searchQuery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paiementsAsync = ref.watch(adminPaiementsProvider);

    return paiementsAsync.when(
      loading: () => Center(child: LoaderPremium()),
      error: (e, _) => Center(child: Text('Erreur: $e', style: const TextStyle(color: Colors.red))),
      data: (paiements) {
        final filtered = searchQuery.isEmpty
            ? paiements
            : paiements.where((p) =>
                p.id.toLowerCase().contains(searchQuery) ||
                p.courseId.toLowerCase().contains(searchQuery) ||
                p.telephonePayeur.toLowerCase().contains(searchQuery) ||
                p.operateur.toLowerCase().contains(searchQuery)).toList();

        if (filtered.isEmpty) {
          return const Center(
              child: Text('Aucun paiement trouvé, espérons que les affaires reprennent vite ! 💸', style: TextStyle(color: Colors.white38)));
        }

        final totalGeneral = filtered.fold(0.0, (sum, p) => sum + p.montant);

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: filtered.length + 1,
          itemBuilder: (ctx, i) {
            if (i == 0) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [CouleursApp.primaire.withValues(alpha: 0.3), CouleursApp.primaire.withValues(alpha: 0.1)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total (${filtered.length} paiements)',
                        style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    Text('${NumberFormat('#,##0', 'fr_FR').format(totalGeneral)} FCFA',
                        style: GoogleFonts.inter(
                            color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }
            return _CartePaiement(paiement: filtered[i - 1]);
          },
        );
      },
    );
  }
}

class _CartePaiement extends ConsumerWidget {
  final Paiement paiement;
  const _CartePaiement({required this.paiement});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estAbonnement = paiement.courseId.startsWith('SUB-');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: estAbonnement
                  ? Colors.purple.withValues(alpha: 0.15)
                  : Colors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              estAbonnement ? Icons.workspace_premium : Icons.payments_outlined,
              color: estAbonnement ? Colors.purple : Colors.green,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  estAbonnement ? 'Abonnement' : 'Course #${paiement.courseId.substring(0, 8).toUpperCase()}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text('${paiement.operateur} • ${paiement.telephonePayeur}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
                Text(DateFormat('dd/MM/yyyy HH:mm').format(paiement.datePaiement),
                    style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${paiement.montant.toInt()} F',
                  style: GoogleFonts.inter(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(paiement.statut,
                    style: const TextStyle(color: Colors.greenAccent, fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ONGLET CONVERSATIONS
// ============================================================
class _OngletConversations extends ConsumerWidget {
  final String searchQuery;
  const _OngletConversations({required this.searchQuery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(adminToutesConversationsProvider);

    return conversationsAsync.when(
      loading: () => Center(child: LoaderPremium()),
      error: (e, _) => Center(child: Text('Erreur: $e', style: const TextStyle(color: Colors.red))),
      data: (conversations) {
        final filtered = searchQuery.isEmpty
            ? conversations
            : conversations.where((c) =>
                (c['conversationId'] as String).toLowerCase().contains(searchQuery)).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.chat_bubble_outline, size: 64, color: Colors.white12),
                SizedBox(height: 12),
                Text('Aucune conversation pour le moment. 🕊️', style: TextStyle(color: Colors.white38, fontSize: 16)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: filtered.length,
          itemBuilder: (ctx, i) => _CarteConversation(conv: filtered[i]),
        );
      },
    );
  }
}

class _CarteConversation extends ConsumerStatefulWidget {
  final Map<String, dynamic> conv;
  const _CarteConversation({required this.conv});

  @override
  ConsumerState<_CarteConversation> createState() => _CarteConversationState();
}

class _CarteConversationState extends ConsumerState<_CarteConversation> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final convId = widget.conv['conversationId'] as String;
    final nbMessages = widget.conv['nombreMessages'] as int;
    final dernierMsg = widget.conv['dernierMessage'] as Map<String, dynamic>;
    final contenu = dernierMsg['contenu'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF1E3A5F),
              child: Icon(Icons.chat, color: Colors.blueAccent, size: 20),
            ),
            title: Text(convId,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text(
              '$nbMessages message(s) • "$contenu"',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: TextButton.icon(
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.blueAccent, size: 18),
              label: Text(_expanded ? 'Fermer' : 'Lire',
                  style: const TextStyle(color: Colors.blueAccent, fontSize: 12)),
            ),
          ),
          if (_expanded) _buildMessages(context, convId),
        ],
      ),
    );
  }

  Widget _buildMessages(BuildContext context, String convId) {
    final messagesAsync = ref.watch(adminMessagesConversationProvider(convId));

    return messagesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: LoaderPremium(size: 24)),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Erreur: $e', style: const TextStyle(color: Colors.red)),
      ),
      data: (messages) {
        return Container(
          constraints: const BoxConstraints(maxHeight: 300),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            children: [
              const Divider(color: Colors.white12),
              Expanded(
                child: ListView.builder(
                  reverse: false,
                  itemCount: messages.length,
                  itemBuilder: (ctx, i) {
                    final msg = messages[i];
                    final expediteur = msg['expediteurId'] as String? ?? '';
                    final texte = msg['contenu'] as String? ?? '';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'De : ${expediteur.substring(0, expediteur.length.clamp(0, 12))}...',
                            style: const TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(texte,
                              style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
