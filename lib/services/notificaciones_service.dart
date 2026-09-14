import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificacionesService {
  static final FlutterLocalNotificationsPlugin _notificacionesPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> inicializar() async {
    tz.initializeTimeZones();
    // Ajusta la zona horaria local (GTM-6)
    tz.setLocalLocation(tz.getLocation('America/Mexico_City'));

    // 🚀 CORRECCIÓN: Apuntando al ícono real de tu app que no es borrado por R8
    const AndroidInitializationSettings androidConfig = AndroidInitializationSettings('@mipmap/launcher_icon');
    
    // Configuración para iOS
    const DarwinInitializationSettings iosConfig = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidConfig,
      iOS: iosConfig,
    );

    await _notificacionesPlugin.initialize(
      settings: initSettings,
    );

    // Solicitar permisos explícitos en Android 13+
    _notificacionesPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
  }

  // Programa una alerta para una fecha y hora exacta
  static Future<void> programarRecordatorio({
    required int id, 
    required String titulo,
    required String cuerpo,
    required DateTime fechaProgramada,
  }) async {
    // Si la fecha ya pasó, no programamos nada
    if (fechaProgramada.isBefore(DateTime.now())) return;

    await _notificacionesPlugin.zonedSchedule(
      id: id,
      title: titulo,
      body: cuerpo,
      scheduledDate: tz.TZDateTime.from(fechaProgramada, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'entregas_channel', // ID del canal interno
          'Recordatorios de Entregas', // Nombre visible en ajustes del teléfono
          channelDescription: 'Avisos para las entregas agendadas en la app',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // Cancela una notificación (por si reagendan o cancelan el carrito)
  static Future<void> cancelarRecordatorio(int id) async {
    await _notificacionesPlugin.cancel(id: id);
  }
}