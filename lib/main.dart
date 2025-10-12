import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nutrimap/l10n/app_localizations.dart';
import 'package:nutrimap/screens/auth/login_screen.dart';
import 'package:nutrimap/screens/auth/register_screen.dart';
import 'package:nutrimap/screens/info_screen.dart';
import 'package:nutrimap/screens/main_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('es');
  bool _isFirstRun = true;
  bool _loading = true;

  // Cambia esto a false en producción
  final bool _isDevMode = false;

  @override
  void initState() {
    super.initState();
    _checkFirstRun();
  }

  Future<void> _checkFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    final seenInfo = prefs.getBool('seenInfo') ?? false;

    setState(() {
      _isFirstRun = _isDevMode ? true : !seenInfo;
      _loading = false;
    });
  }

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  void _completeInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenInfo', true);

    navigatorKey.currentState!.pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'NutriMap',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.dark,
      locale: _locale,
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: _isFirstRun
          ? InfoScreen(onLocaleChange: setLocale, onFinished: _completeInfo)
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
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterPage(),
      },
    );
  }
}
