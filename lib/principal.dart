import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'coeur/routes/routes.dart';
import 'coeur/theme/theme_application.dart';

class MonApplication extends StatelessWidget {
  const MonApplication({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: "Transport Intelligent IA",

          theme: ThemeApplication.themeClair,
          darkTheme: ThemeApplication.themeSombre,
          themeMode: ThemeMode.system,

          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('fr', ''),
          ],

          routerConfig: RoutesApplication.routeur,
        );
      },
    );
  }
}