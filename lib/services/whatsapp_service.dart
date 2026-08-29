import 'package:url_launcher/url_launcher.dart';

class WhatsappService {
  static Future<void> abrirChat(String telefono) async {
    print('WhatsApp - teléfono recibido: "$telefono"');

    // Eliminar todo excepto números
    String numero = telefono.replaceAll(RegExp(r'[^0-9]'), '');

    print('WhatsApp - teléfono limpio: "$numero"');

    // Si es un número mexicano de 10 dígitos
    if (numero.length == 10) {
      numero = '52$numero';
    }

    // Compatibilidad con números que tengan 521
    if (numero.length == 13 && numero.startsWith('521')) {
      numero = '52${numero.substring(3)}';
    }

    print('WhatsApp - número final: "$numero"');

    // Validar número mexicano
    if (numero.length != 12 || !numero.startsWith('52')) {
      throw Exception(
        'Número inválido: $telefono -> $numero',
      );
    }

    final Uri url = Uri.parse(
      'https://wa.me/$numero',
    );

    print('WhatsApp - URL: $url');

    // Abrir directamente
    final resultado = await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );

    if (!resultado) {
      throw Exception(
        'Android no pudo abrir el enlace de WhatsApp.',
      );
    }
  }
}