import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:update_camtrans/services/service_notification.dart';
import 'package:update_camtrans/coeur/constantes/couleurs.dart';

/// Widget global qui écoute le [fluxNotificationsInApp] et affiche
/// une bannière animée en haut de l'écran pendant 4 secondes.
///
/// À placer dans le widget racine de l'app (ex: MaterialApp.builder).
class EcouteurNotificationsApp extends StatefulWidget {
  final Widget child;
  const EcouteurNotificationsApp({super.key, required this.child});

  @override
  State<EcouteurNotificationsApp> createState() =>
      _EcouteurNotificationsAppState();
}

class _EcouteurNotificationsAppState extends State<EcouteurNotificationsApp> {
  StreamSubscription<NotificationInApp>? _sub;
  final List<_EntreeNotification> _bannieres = [];

  @override
  void initState() {
    super.initState();
    _sub = fluxNotificationsInApp.listen(_afficher);
  }

  void _afficher(NotificationInApp notif) {
    if (!mounted) return;
    final entree = _EntreeNotification(notif: notif, key: UniqueKey());
    setState(() => _bannieres.add(entree));
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => _bannieres.remove(entree));
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        // Pile de bannières en haut de l'écran
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          child: Column(
            children: _bannieres.map((e) => _BanniereNotification(
              key: e.key,
              notif: e.notif,
              onDismiss: () {
                if (mounted) setState(() => _bannieres.remove(e));
              },
            )).toList(),
          ),
        ),
      ],
    );
  }
}

class _EntreeNotification {
  final NotificationInApp notif;
  final Key key;
  _EntreeNotification({required this.notif, required this.key});
}

class _BanniereNotification extends StatelessWidget {
  final NotificationInApp notif;
  final VoidCallback onDismiss;

  const _BanniereNotification({
    super.key,
    required this.notif,
    required this.onDismiss,
  });

  Color get _couleurAccent {
    switch (notif.type) {
      case 'succes':
        return CouleursApp.succes;
      case 'alerte':
        return CouleursApp.avertissement;
      case 'paiement':
        return const Color(0xFFF59E0B); // Amber
      default:
        return CouleursApp.primaire;
    }
  }

  IconData get _icone {
    switch (notif.type) {
      case 'succes':
        return Iconsax.tick_circle_copy;
      case 'alerte':
        return Iconsax.warning_2_copy;
      case 'paiement':
        return Iconsax.wallet_3_copy;
      default:
        return Iconsax.notification_copy;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onDismiss,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _couleurAccent.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: _couleurAccent.withValues(alpha: 0.15),
                blurRadius: 20,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _couleurAccent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: _couleurAccent.withValues(alpha: 0.3)),
                ),
                child: Icon(_icone, color: _couleurAccent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notif.titre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notif.message,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.close, color: Colors.white38, size: 16),
            ],
          ),
        )
        ,
      ),
    );
  }
}
