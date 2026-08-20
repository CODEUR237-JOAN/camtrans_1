import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:update_camtrans/coeur/routes/routes.dart';
import 'package:update_camtrans/coeur/theme/theme_application.dart';
import 'package:update_camtrans/coeur/etat/notification_provider.dart';
import 'package:update_camtrans/coeur/widgets/banniere_notification.dart';

class MonApplication extends ConsumerWidget {
  const MonApplication({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialise l'écoute du token FCM
    ref.watch(gestionTokenFCMProvider);

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return EcouteurNotificationsApp(
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: "Transport Intelligent",

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
          ),
        );
      },
    );
  }
}