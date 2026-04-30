import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/inventario_provider.dart';
import 'ui/screens/dashboard_screen.dart';
import 'ui/screens/inventario_screen.dart';
import 'ui/screens/finanzas_screen.dart';
import 'ui/screens/carritos_activos_screen.dart'; // <-- IMPORT NUEVO
import 'data/storage_service.dart'; // <-- IMPORT NUEVO PARA EL SALDO

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

  // <-- Se agregó la nueva pantalla a la lista
  final List<Widget> _pantallas = [
    const DashboardScreen(),
    const InventarioScreen(),
    const FinanzasScreen(),
    const CarritosActivosScreen(), 
  ];

  @override
  void initState() {
    super.initState();
    // Esto dispara la validación del saldo inicial justo después de que la pantalla carga
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarSaldoInicial();
    });
  }

  // --- LÓGICA DEL SALDO INICIAL ---
  Future<void> _verificarSaldoInicial() async {
    bool primeraVez = await StorageService.isPrimeraVez();
    if (primeraVez) {
      _mostrarDialogoSaldoInicial();
    }
  }

  void _mostrarDialogoSaldoInicial() {
    final TextEditingController _saldoController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false, // Evita que lo cierren tocando afuera
      builder: (context) {
        return WillPopScope(
          onWillPop: () async => false, // Evita que usen el botón de retroceso de Android
          child: AlertDialog(
            title: const Text('¡Bienvenida, Paola!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Como el negocio ya está en marcha, ¿con cuánto saldo en caja iniciamos?'),
                const SizedBox(height: 15),
                TextField(
                  controller: _saldoController,
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
                  if (_saldoController.text.isNotEmpty) {
                    double saldo = double.tryParse(_saldoController.text) ?? 0.0;
                    
                    await StorageService.guardarSaldoInicial(saldo);
                    await StorageService.setPrimeraVezCompletada();
                    
                    if (mounted) {
                      // Inyectamos el saldo en el Provider para que actualice la caja
                      context.read<InventarioProvider>().agregarSaldoInicial(saldo);
                      Navigator.of(context).pop();
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
  // --------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('W A V E  S T O R E', 
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
      ),
      body: _pantallas[_indiceActual],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // <-- IMPORTANTE: Evita que se rompa el diseño al tener 4 botones
        currentIndex: _indiceActual,
        onTap: (index) => setState(() => _indiceActual = index),
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Resumen'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Inventario'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Historial'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Apartados'), // <-- NUEVO BOTÓN
        ],
      ),
    );
  }
}