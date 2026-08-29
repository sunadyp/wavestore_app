import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/inventario_provider.dart';
import 'ui/screens/dashboard_screen.dart';
import 'ui/screens/inventario_screen.dart';
import 'ui/screens/finanzas_screen.dart';
import 'ui/screens/carritos_activos_screen.dart'; 
import 'ui/screens/reportes_screen.dart';
import 'ui/screens/bitacora_actividades.dart'; // <-- NUEVA IMPORTACIÓN
import 'data/storage_service.dart'; 

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
    const CarritosActivosScreen(), 
    const ReportesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarSaldoInicial();
    });
  }

  Future<void> _verificarSaldoInicial() async {
    bool primeraVez = await StorageService.isPrimeraVez();
    if (primeraVez) {
      _mostrarDialogoSaldoInicial();
    }
  }

  void _mostrarDialogoSaldoInicial() {
    final TextEditingController saldoController = TextEditingController();
    final inventarioProvider = context.read<InventarioProvider>();

    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (dialogContext) {
        return PopScope(
          canPop: false, 
          child: AlertDialog(
            title: const Text('¡Bienvenida, amooooor!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('¿Con cuántos millones iniciamos?'),
                const SizedBox(height: 15),
                TextField(
                  controller: saldoController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Saldo Inicial',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (saldoController.text.isNotEmpty) {
                    double saldo = double.tryParse(saldoController.text) ?? 0.0;
                    
                    await StorageService.guardarSaldoInicial(saldo);
                    await StorageService.setPrimeraVezCompletada();
                    
                    if (mounted) {
                      inventarioProvider.agregarSaldoInicial(saldo);
                      Navigator.of(dialogContext).pop();
                    }
                  }
                },
                child: const Text('Comenzar'),
              ),
            ],
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('W A V E  S T O R E', 
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
        // <-- NUEVO: Botón de Bitácora Global
        actions: [
          IconButton(
            icon: const Icon(Icons.history_toggle_off_rounded),
            tooltip: 'Registro de Actividad',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BitacoraActividades()),
              );
            },
          ),
        ],
      ),
      body: _pantallas[_indiceActual],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, 
        currentIndex: _indiceActual,
        onTap: (index) => setState(() => _indiceActual = index),
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Resumen'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Inventario'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Historial'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Apartados'), 
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Reportes'),
        ],
      ),
    );
  }
}