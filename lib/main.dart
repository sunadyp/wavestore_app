import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/inventario_provider.dart';
import 'ui/screens/dashboard_screen.dart';
import 'ui/screens/inventario_screen.dart';
import 'ui/screens/finanzas_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
    // Definimos los colores aquí para que toda la app los herede
    const Color rosaPrincipal = Color(0xFFF06292);
    const Color rosaAcento = Color(0xFFF8BBD0);

    return MaterialApp(
      title: 'WaveStore',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: rosaPrincipal,
          primary: rosaPrincipal,
          secondary: rosaAcento,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: rosaPrincipal,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
      ),
      // Si el sistema de rutas te dio problemas, volvamos a lo seguro:
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

  final List<Widget> _pantallas = [
    const DashboardScreen(),
    const InventarioScreen(),
    const FinanzasScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // El AppBar se queda aquí para que sea persistente
      appBar: AppBar(
        title: const Text('W A V E  S T O R E', 
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
      ),
      body: _pantallas[_indiceActual],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceActual,
        onTap: (index) => setState(() => _indiceActual = index),
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Resumen'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Inventario'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Historial'),
        ],
      ),
    );
  }
}