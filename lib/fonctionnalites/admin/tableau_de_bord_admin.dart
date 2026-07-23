import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../coeur/etat/admin_provider.dart';
import 'widgets/sidebar_admin.dart';
import 'pages/page_vue_ensemble.dart';
import 'pages/page_utilisateurs.dart';
import 'pages/page_moderation.dart';

class TableauDeBordAdmin extends ConsumerStatefulWidget {
  const TableauDeBordAdmin({super.key});

  @override
  ConsumerState<TableauDeBordAdmin> createState() => _TableauDeBordAdminState();
}

class _TableauDeBordAdminState extends ConsumerState<TableauDeBordAdmin> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Écouter les changements d'index du menu latéral
    ref.listen<int>(adminMenuIndexProvider, (previous, next) {
      if (previous != next) {
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });

    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      // Sur mobile/tablette on met un Drawer
      drawer: !isDesktop ? const Drawer(child: SidebarAdmin()) : null,
      appBar: !isDesktop
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.black87),
              title: const Text("CamTrans Admin", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
            )
          : null, // Pas d'appBar sur Desktop, la sidebar gère tout
      body: Row(
        children: [
          // Sidebar pour Desktop
          if (isDesktop) const SidebarAdmin(),
          
          // Zone de contenu
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(), // Désactive le swipe manuel
              children: [
                const PageVueEnsemble().animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),
                const PageUtilisateurs().animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),
                const PageModeration().animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),
                // Les futures pages (Courses, Signalements) iront ici
              ],
            ),
          ),
        ],
      ),
    );
  }
}
