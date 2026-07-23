import 'package:flutter/material.dart';

class Responsive extends StatelessWidget {
  final Widget mobile;
  final Widget? tablette;
  final Widget bureau;

  const Responsive({
    super.key,
    required this.mobile,
    this.tablette,
    required this.bureau,
  });

  // Limites des tailles d'écrans standard
  static bool estMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 650;

  static bool estTablette(BuildContext context) =>
      MediaQuery.of(context).size.width >= 650 &&
      MediaQuery.of(context).size.width < 1100;

  static bool estBureau(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1100;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1100) {
          return bureau;
        }
        else if (constraints.maxWidth >= 650) {
          return tablette ?? mobile;
        }
        else {
          return mobile;
        }
      },
    );
  }
}
