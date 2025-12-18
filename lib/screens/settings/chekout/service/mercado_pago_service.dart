import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

Future<String?> crearPreferenciaPago() async {
  const String accessToken =
      'APP_USR-2396912505270458-111218-90b423031ae788a8b1dc51cc7fd1a4f7-216182007';

  final url = Uri.parse('https://api.mercadopago.com/checkout/preferences');
  final response = await http.post(
    url,
    headers: {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      "items": [
        {
          "title": "Premium",
          "quantity": 1,
          "unit_price": 50,
          "currency_id": "CLP",
        },
      ],
      "back_urls": {
        "success": "https://tuapp.com/success",
        "failure": "https://tuapp.com/failure",
        "pending": "https://tuapp.com/pending",
      },
      "auto_return": "approved",
    }),
  );

  if (response.statusCode == 201) {
    final data = jsonDecode(response.body);
    return data['init_point'];
  } else {
    if (kDebugMode) {
      print('Error creando preferencia: ${response.body}');
    }
    return null;
  }
}
