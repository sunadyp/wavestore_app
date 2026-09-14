import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class BackupService {
  static const String _appName = "Wave Store";
  static const int _backupVersion = 1;

  /// Exporta toda la base de datos actual a un archivo JSON y abre el diálogo para compartirlo.
  static Future<bool> exportarRespaldo() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Recolectar los datos crudos directamente de SharedPreferences
      final Map<String, dynamic> backupData = {
        "metadata": {
          "app": _appName,
          "backupVersion": _backupVersion,
          "createdAt": DateTime.now().toIso8601String(),
        },
        "data": {
          "inventario_key": prefs.getString('inventario_key'),
          "ventas_key": prefs.getString('ventas_key'),
          "movimientos_key": prefs.getString('movimientos_key'),
          "actividades_key": prefs.getString('actividades_key'),
          "carritos_key": prefs.getString('carritos_key'),
          "categorias_key": prefs.getStringList('categorias_key'),
          "caja_key": prefs.getDouble('caja_key'),
          "primera_vez": prefs.getBool('primera_vez'),
        }
      };

      // 2. Convertir a un string JSON formateado
      final String jsonBackup = json.encode(backupData);

      // 3. Crear un archivo temporal en el dispositivo
      final directory = await getApplicationDocumentsDirectory();
      // Formateamos la fecha para el nombre del archivo (ej. wavestore_backup_2026-09-16.json)
      final String timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final File file = File('${directory.path}/wavestore_backup_$timestamp.json');
      
      await file.writeAsString(jsonBackup);

      // 4. Compartir el archivo (Drive, WhatsApp, Correo, etc.)
      final result = await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Respaldo de seguridad Wave Store',
      );

      return result.status == ShareResultStatus.success;
    } catch (e) {
      debugPrint("Error al exportar respaldo: $e");
      return false;
    }
  }

  /// Recibe el contenido de un archivo JSON y reemplaza los datos actuales.
  static Future<bool> restaurarRespaldo(String jsonString) async {
    try {
      final Map<String, dynamic> backup = json.decode(jsonString);

      // 1. Validar que sea un archivo de Wave Store
      if (backup['metadata'] == null || backup['metadata']['app'] != _appName) {
        throw Exception("El archivo seleccionado no es un respaldo válido de Wave Store.");
      }

      final Map<String, dynamic> data = backup['data'];
      final prefs = await SharedPreferences.getInstance();

      // 2. Escribir los datos sobreescribiendo el estado actual
      if (data['inventario_key'] != null) await prefs.setString('inventario_key', data['inventario_key']);
      if (data['ventas_key'] != null) await prefs.setString('ventas_key', data['ventas_key']);
      if (data['movimientos_key'] != null) await prefs.setString('movimientos_key', data['movimientos_key']);
      if (data['actividades_key'] != null) await prefs.setString('actividades_key', data['actividades_key']);
      if (data['carritos_key'] != null) await prefs.setString('carritos_key', data['carritos_key']);
      
      // Tratamiento especial para listas y numéricos
      if (data['categorias_key'] != null) {
        await prefs.setStringList('categorias_key', List<String>.from(data['categorias_key']));
      }
      if (data['caja_key'] != null) {
        await prefs.setDouble('caja_key', (data['caja_key'] as num).toDouble());
      }
      if (data['primera_vez'] != null) {
        await prefs.setBool('primera_vez', data['primera_vez']);
      }

      return true;
    } catch (e) {
      debugPrint("Error al restaurar respaldo: $e");
      return false;
    }
  }
}