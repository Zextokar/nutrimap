import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutrimap/l10n/app_localizations.dart';

class BenefitsScreen extends StatelessWidget {
  final User user;
  const BenefitsScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(local.benefits)),
      body: Center(
        child: Text(
          local.benefitsUser(user.email ?? local.user),
          style: const TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
