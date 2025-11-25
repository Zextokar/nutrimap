import 'package:flutter/services.dart';

// 1. FORMATEADOR: Pone puntos y guión automáticamente mientras escribes
class RutFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String rut = newValue.text.toUpperCase().replaceAll(RegExp(r'[^0-9K]'), '');
    if (rut.isEmpty) return newValue.copyWith(text: '');
    if (rut.length < 2) return newValue.copyWith(text: rut);

    String cuerpo = rut.substring(0, rut.length - 1);
    String dv = rut.substring(rut.length - 1);

    String cuerpoFormateado = '';
    int contador = 0;
    for (int i = cuerpo.length - 1; i >= 0; i--) {
      cuerpoFormateado = cuerpo[i] + cuerpoFormateado;
      contador++;
      if (contador == 3 && i != 0) {
        cuerpoFormateado = '.$cuerpoFormateado';
        contador = 0;
      }
    }
    String rutFinal = '$cuerpoFormateado-$dv';
    return TextEditingValue(
      text: rutFinal,
      selection: TextSelection.collapsed(offset: rutFinal.length),
    );
  }
}

// 2. VALIDADOR: Verifica que el RUT sea real matemáticamente
bool esRutValido(String rut) {
  if (rut.isEmpty || !rut.contains('-')) return false;
  String rutLimpio = rut.replaceAll('.', '').toUpperCase();
  List<String> partes = rutLimpio.split('-');
  if (partes.length != 2) return false;

  String num = partes[0];
  String dv = partes[1];
  if (num.isEmpty || dv.isEmpty) return false;

  int suma = 0;
  int multiplicador = 2;
  for (int i = num.length - 1; i >= 0; i--) {
    suma += int.parse(num[i]) * multiplicador;
    multiplicador++;
    if (multiplicador == 8) multiplicador = 2;
  }

  int resto = suma % 11;
  String dvCalculado = (resto == 0)
      ? '0'
      : (resto == 1)
      ? 'K'
      : (11 - resto).toString();
  return dvCalculado == dv;
}
