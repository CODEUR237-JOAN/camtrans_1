import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/constantes/tailles.dart';
import 'package:update_camtrans/coeur/etat/notification_provider.dart';
import 'package:update_camtrans/modeles/notification.dart';
import 'package:update_camtrans/coeur/widgets/loader_premium.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  String filtre = "Toutes";

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(fluxNotificationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF08111F),
      appBar: AppBar(
        title: const Text("Notifications", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF08111F),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF08111F)),
        automaticallyImplyLeading: false,
        actions: [
          notificationsAsync.maybeWhen(
            data: (list) => IconButton(
              onPressed: () => ref.read(notificationActionsProvider).toutMarquerCommeLu(list),
              icon: const Icon(Icons.done_all),
              tooltip: "Tout marquer comme lu",
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(TaillesApp.margePage),
        child: Column(
          children: [
            SizedBox(
              height: 45,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: <Widget>[
                  _filtre("Toutes"),
                  _filtre("Non lues"),
                  _filtre("Courses"),
                  _filtre("Paiements"),
                  _filtre("Messages"),
                  _filtre("Système"),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: notificationsAsync.when(
                loading: () => Center(child: LoaderPremium()),
                error: (err, stack) => Center(child: Text("Erreur: $err")),
                data: (notifications) {
                  final notificationsFiltrees = notifications.where((n) {
                    if (filtre == "Toutes") return true;
                    if (filtre == "Non lues") return !n.lue;
                    return n.categorie == filtre;
                  }).toList();

                  if (notificationsFiltrees.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_none, size: 80, color: Colors.white.withValues(alpha: 0.1)),
                          const SizedBox(height: 16),
                          const Text("Aucune notification", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 120),
                    itemCount: notificationsFiltrees.length,
                    itemBuilder: (context, index) {
                      final notification = notificationsFiltrees[index];
                      return _buildNotificationCard(notification);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationApp notification) {
    Color couleur = Colors.blue;
    IconData icone = Icons.notifications;

    switch (notification.categorie) {
      case 'Courses':
        couleur = Colors.blue;
        icone = Icons.local_shipping;
        break;
      case 'Paiements':
        couleur = Colors.green;
        icone = Icons.payments;
        break;
      case 'Messages':
        couleur = Colors.purple;
        icone = Icons.message;
        break;
      case 'Système':
        couleur = Colors.orange;
        icone = Icons.verified;
        break;
    }

    final timeStr = DateFormat('HH:mm').format(notification.dateCreation);
    final dateStr = DateFormat('dd/MM').format(notification.dateCreation);

    return Card(
      color: const Color(0xFF10192A),
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: notification.lue ? Colors.white.withValues(alpha: 0.05) : couleur.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: couleur.withValues(alpha: 0.1),
          child: Icon(icone, color: couleur, size: 20),
        ),
        title: Text(
          notification.titre,
          style: TextStyle(
            fontWeight: notification.lue ? FontWeight.normal : FontWeight.bold,
            fontSize: 15,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(notification.message, style: TextStyle(color: Colors.white38, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                Text("$dateStr à $timeStr", style: const TextStyle(fontSize: 11, color: Colors.white54)),
                const Spacer(),
                if (!notification.lue)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: couleur, shape: BoxShape.circle),
                  ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == "Supprimer") {
              ref.read(notificationActionsProvider).supprimer(notification.id);
            } else if (value == "Marquer comme lu") {
              ref.read(notificationActionsProvider).marquerCommeLue(notification.id);
            }
          },
          itemBuilder: (context) => [
            if (!notification.lue)
              const PopupMenuItem(value: "Marquer comme lu", child: Text("Marquer comme lu")),
            const PopupMenuItem(value: "Supprimer", child: Text("Supprimer")),
          ],
        ),
      ),
    );
  }

  Widget _filtre(String valeur) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(valeur),
        selected: filtre == valeur,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              filtre = valeur;
            });
          }
        },
        selectedColor: CouleursApp.primaire,
        labelStyle: TextStyle(color: filtre == valeur ? Colors.white : Colors.white54),
      ),
    );
  }
}
