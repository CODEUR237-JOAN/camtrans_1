import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;


/// =======================================================
/// TRANSITIONS DE PAGE PERSONNALISÉES
/// Pour GoRouter - Effets fluides et modernes
/// =======================================================

/// -------------------------------------------------------
/// FADE SCALE TRANSITION
/// Apparition en fondu + scale subtil
/// -------------------------------------------------------
class FadeScaleTransition extends CustomTransitionPage {
  FadeScaleTransition({
    required super.child,
    super.name,
    super.arguments,
    super.restorationId,
    super.key,
  }) : super(
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: const Interval(0, 0.6, curve: Curves.easeOut),
              ),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.96, end: 1.0).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: const Interval(0, 0.6, curve: Curves.easeOutCubic),
                  ),
                ),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
        );
}

/// -------------------------------------------------------
/// SLIDE UP TRANSITION
/// Glissement depuis le bas (idéal pour les modals)
/// -------------------------------------------------------
class SlideUpTransition extends CustomTransitionPage {
  SlideUpTransition({
    required super.child,
    super.name,
    super.arguments,
    super.restorationId,
    super.key,
  }) : super(
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 0.15);
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;

            final tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            return FadeTransition(
              opacity: animation.drive(
                Tween(begin: 0.0, end: 1.0).chain(
                  CurveTween(curve: const Interval(0, 0.5, curve: Curves.easeOut)),
                ),
              ),
              child: SlideTransition(
                position: animation.drive(tween),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 450),
          reverseTransitionDuration: const Duration(milliseconds: 350),
        );
}

/// -------------------------------------------------------
/// SHARED AXIS TRANSITION
/// Transition d'axe partagé (comme Material Motion)
/// -------------------------------------------------------
class SharedAxisTransition extends CustomTransitionPage {
  final SharedAxisTransitionType type;

  SharedAxisTransition({
    required super.child,
    this.type = SharedAxisTransitionType.horizontal,
    super.name,
    super.arguments,
    super.restorationId,
    super.key,
  }) : super(
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                final fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: const Interval(0, 0.4, curve: Curves.easeOut),
                  ),
                );

                Offset slideBegin;
                switch (type) {
                  case SharedAxisTransitionType.horizontal:
                    slideBegin = const Offset(0.15, 0);
                    break;
                  case SharedAxisTransitionType.vertical:
                    slideBegin = const Offset(0, 0.1);
                    break;
                  case SharedAxisTransitionType.scaled:
                    slideBegin = Offset.zero;
                    break;
                }

                return FadeTransition(
                  opacity: fadeAnimation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: slideBegin,
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                    child: type == SharedAxisTransitionType.scaled
                        ? ScaleTransition(
                            scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                            child: child,
                          )
                        : child,
                  ),
                );
              },
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
        );
}

enum SharedAxisTransitionType {
  horizontal,
  vertical,
  scaled,
}

/// -------------------------------------------------------
/// HERO FADE TRANSITION
/// Transition hero avec fondu (pour les détails)
/// -------------------------------------------------------
class HeroFadeTransition extends CustomTransitionPage {
  HeroFadeTransition({
    required super.child,
    super.name,
    super.arguments,
    super.restorationId,
    super.key,
  }) : super(
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 200),
        );
}

/// -------------------------------------------------------
/// CUBIC TRANSITION
/// Transition cubique 3D
/// -------------------------------------------------------
class CubicTransition extends CustomTransitionPage {
  CubicTransition({
    required super.child,
    super.name,
    super.arguments,
    super.restorationId,
    super.key,
  }) : super(
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                final rotateAnim = Tween<double>(begin: 0.1, end: 0.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                );
                final scaleAnim = Tween<double>(begin: 0.9, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                );

                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(rotateAnim.value)
                    ..scaleByVector3(Vector3(scaleAnim.value, scaleAnim.value, 1.0)),
                  alignment: Alignment.centerLeft,
                  child: FadeTransition(
                    opacity: animation.drive(
                      Tween<double>(begin: 0.5, end: 1.0).chain(
                        CurveTween(curve: Curves.easeOut),
                      ),
                    ),
                    child: child,
                  ),
                );
              },
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 400),
        );
}

