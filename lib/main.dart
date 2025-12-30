import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'package:nutrimap/l10n/app_localizations.dart';
import 'package:nutrimap/providers/locale_provider.dart';
import 'package:nutrimap/screens/auth/login_screen.dart';
import 'package:nutrimap/screens/auth/register_screen.dart';
import 'package:nutrimap/screens/main_screen.dart';
import 'package:nutrimap/screens/info/info_screen.dart';
import 'package:nutrimap/screens/settings/chekout/subscription_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LocaleProvider(),
      child: Consumer<LocaleProvider>(
        builder: (context, provider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'NutriMap',
            theme: ThemeData(
              useMaterial3: true,
              fontFamily: 'Ubuntu',
              brightness: Brightness.light,
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              fontFamily: 'Ubuntu',
              brightness: Brightness.dark,
            ),
            themeMode: ThemeMode.dark,
            locale: provider.locale,
            supportedLocales: const [Locale('es'), Locale('en')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasData) {
                  return MainScreen(user: snapshot.data!);
                }

                return InfoScreen(
                  onFinished: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  onLocaleChange: (Locale p1) {},
                );
              },
            ),
            routes: {
              '/login': (_) => const LoginScreen(),
              '/register': (_) => const RegisterPage(),
              '/subscription': (_) => const SubscriptionScreen(),
            },
          );
        },
      ),
    );
  }
}
