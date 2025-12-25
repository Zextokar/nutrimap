import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isFirstRun = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkFirstRun();
  }

  Future<void> _checkFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    final seenInfo = prefs.getBool('seenInfo') ?? false;

    setState(() {
      _isFirstRun = !seenInfo;
      _loading = false;
    });
  }

  Future<void> _completeInfo(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenInfo', true);

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LocaleProvider(),
      child: Consumer<LocaleProvider>(
        builder: (context, provider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'NutriMap',
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: ThemeMode.dark,
            locale: provider.locale,
            supportedLocales: const [Locale('es'), Locale('en')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: _loading
                ? const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  )
                : _isFirstRun
                ? InfoScreen(onFinished: () => _completeInfo(context), onLocaleChange: (Locale p1) {  },)
                : StreamBuilder<User?>(
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
                      return const LoginScreen();
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
