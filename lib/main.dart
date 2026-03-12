import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'screens/inventario_screen.dart';
import 'screens/finanzas_screen.dart'; // 1. IMPORTA LA NUEVA PANTALLA
import 'package:provider/provider.dart';
import 'providers/inventario_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => InventarioProvider()),
      ],
      child: const WaveStoreApp(),
    ),
  );
}

class WaveStoreApp extends StatelessWidget {
  const WaveStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color rosaPrincipal = Color(0xFFF06292);
    const Color rosaAcento = Color(0xFFF8BBD0);
    const Color fondo = Color(0xFFFAFAFA);

    return MaterialApp(
      title: 'WaveStore',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: fondo,
        colorScheme: ColorScheme.fromSeed(
          seedColor: rosaPrincipal,
          primary: rosaPrincipal,
          secondary: rosaAcento,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: rosaPrincipal,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        useMaterial3: true,
      ),
      home: const NavegacionPrincipal(),
    );
  }
}

class NavegacionPrincipal extends StatefulWidget {
  const NavegacionPrincipal({super.key});

  @override
  State<NavegacionPrincipal> createState() => _NavegacionPrincipalState();
}

class _NavegacionPrincipalState extends State<NavegacionPrincipal> {
  int _indiceActual = 0;

  // 2. AÑADE LA PANTALLA A LA LISTA
  final List<Widget> _pantallas = [
    const DashboardScreen(),
    const InventarioScreen(),
    const FinanzasScreen(), // <-- Agregada aquí
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('W A V E  S T O R E'),
      ),
      body: _pantallas[_indiceActual],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceActual,
        onTap: (index) {
          setState(() {
            _indiceActual = index;
          });
        },
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        // 3. AÑADE EL ICONO EN EL MENÚ
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_rounded),
            label: 'Resumen',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_rounded),
            label: 'Inventario',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_rounded),
            label: 'Historial',
          ),
        ],
      ),
    );
  }
}