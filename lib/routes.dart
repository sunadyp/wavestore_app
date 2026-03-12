import 'package:flutter/material.dart';
import 'ui/screens/dashboard_screen.dart';
import 'ui/screens/inventario_screen.dart';
import 'ui/screens/finanzas_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String inventario = '/inventario';
  static const String finanzas = '/finanzas';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      // Por ahora, como usas NavegacionPrincipal, 
      // las rutas internas se manejan en el main, 
      // pero esto nos sirve para navegaciones directas (Push).
      home: (context) => const DashboardScreen(),
      inventario: (context) => const InventarioScreen(),
      finanzas: (context) => const FinanzasScreen(),
    };
  }
}