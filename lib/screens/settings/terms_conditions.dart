import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    //  Detecta idioma actual
    final localeCode = Localizations.localeOf(context).languageCode;
    final bool isSpanish = localeCode == 'es';

    //  Colores
    const Color primaryDark = Color.fromARGB(177, 2, 56, 114);
    const Color secondaryDark = Color.fromARGB(255, 1, 17, 46);
    const Color textPrimary = Color(0xFFE0E1DD);
    const Color accentGreen = Color.fromARGB(255, 17, 92, 1);

    //  Textos según idioma
    final String titleText = isSpanish
        ? "Términos y Condiciones"
        : "Terms and Conditions";

    final String acceptText = isSpanish ? "Aceptar" : "Accept";

    final String termsText = isSpanish
        ? '''Bienvenido a nuestra aplicación. Antes de usarla, por favor lee atentamente los siguientes términos y condiciones:

1. Uso de la aplicación: El usuario se compromete a utilizar la aplicación de manera responsable y conforme a la ley.

2. Privacidad: Todos los datos proporcionados serán tratados de acuerdo a nuestra política de privacidad.

3. Responsabilidad: No nos hacemos responsables por cualquier daño directo o indirecto que pueda surgir del uso de la aplicación.

4. Propiedad intelectual: Todo el contenido dentro de la app está protegido por derechos de autor y no puede ser reproducido sin permiso.

5. Modificaciones: Nos reservamos el derecho de modificar estos términos en cualquier momento. El uso continuado de la app implica aceptación de los cambios.

6. Aceptación: Al presionar el botón "Aceptar", el usuario reconoce que ha leído y comprendido estos términos y condiciones.

Gracias por utilizar nuestra aplicación.'''
        : '''Welcome to our application. Before using it, please carefully read the following terms and conditions:

1. Use of the application: The user agrees to use the application responsibly and in accordance with the law.

2. Privacy: All provided data will be handled according to our privacy policy.

3. Liability: We are not responsible for any direct or indirect damage that may arise from the use of the application.

4. Intellectual property: All content within the app is protected by copyright and may not be reproduced without permission.

5. Modifications: We reserve the right to modify these terms at any time. Continued use of the app implies acceptance of the changes.

6. Acceptance: By pressing the "Accept" button, the user acknowledges that they have read and understood these terms and conditions.

Thank you for using our application.''';

    return Scaffold(
      backgroundColor: primaryDark,
      appBar: AppBar(
        backgroundColor: primaryDark,
        elevation: 0,
        title: Text(
          titleText,
          style: const TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: secondaryDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: accentGreen.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      termsText,
                      style: const TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    acceptText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
