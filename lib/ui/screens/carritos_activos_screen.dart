import 'package:flutter/material.dart';
import '../widgets/tab_cuentas_activas.dart';
import '../widgets/tab_agenda_entregas.dart';

class CarritosActivosScreen extends StatelessWidget {
  const CarritosActivosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0, 
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.shopping_cart_checkout), text: 'Apartados Activos'),
              Tab(icon: Icon(Icons.calendar_month), text: 'Agenda'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            TabCuentasActivas(),
            TabAgendaEntregas(),
          ],
        ),
      ),
    );
  }
}