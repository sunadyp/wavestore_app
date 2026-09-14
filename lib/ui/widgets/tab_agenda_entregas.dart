import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/venta.dart';
import '../../providers/inventario_provider.dart';

class TabAgendaEntregas extends StatelessWidget {
  const TabAgendaEntregas({super.key});

  // Helper para mostrar la fecha de forma amigable (Ej. "Hoy, 4:00 PM")
  String _formatearFechaAmigable(DateTime? fecha) {
    if (fecha == null) return 'Sin fecha asignada';
    
    final hoy = DateTime.now();
    final manana = hoy.add(const Duration(days: 1));
    
    final esHoy = fecha.year == hoy.year && fecha.month == hoy.month && fecha.day == hoy.day;
    final esManana = fecha.year == manana.year && fecha.month == manana.month && fecha.day == manana.day;
    
    String dia = esHoy ? 'Hoy' : esManana ? 'Mañana' : '${fecha.day}/${fecha.month}/${fecha.year}';
    
    int hora12 = fecha.hour > 12 ? fecha.hour - 12 : (fecha.hour == 0 ? 12 : fecha.hour);
    String minutos = fecha.minute.toString().padLeft(2, '0');
    String amPm = fecha.hour >= 12 ? 'PM' : 'AM';
    
    return '$dia, $hora12:$minutos $amPm';
  }

  // Helper para el color de urgencia
  Color _colorUrgencia(DateTime? fecha) {
    if (fecha == null) return Colors.grey.shade300;
    final ahora = DateTime.now();
    if (fecha.isBefore(ahora)) return Colors.red.shade400; // Atrasado
    if (fecha.difference(ahora).inDays == 0 && fecha.day == ahora.day) return const Color.fromARGB(255, 238, 255, 0); // Es hoy
    return const Color.fromARGB(255, 23, 196, 0); // Futuro
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InventarioProvider>(
      builder: (context, provider, child) {
        // Obtenemos los carritos y los ordenamos por fecha
        final listaAgenda = provider.carritosActivos.entries.toList();
        
        listaAgenda.sort((a, b) {
          final fechaA = a.value.fechaEntrega;
          final fechaB = b.value.fechaEntrega;
          if (fechaA == null && fechaB == null) return 0;
          if (fechaA == null) return 1; // Los que no tienen fecha van al final
          if (fechaB == null) return -1;
          return fechaA.compareTo(fechaB);
        });

        if (listaAgenda.isEmpty) {
          return const Center(
            child: Text(
              'No hay entregas pendientes.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: listaAgenda.length,
          itemBuilder: (context, index) {
            final entry = listaAgenda[index];
            final identificador = entry.key;
            final carrito = entry.value;

            // Determinar estado de pago para el badge visual
            Color colorPago = Colors.red.shade100;
            Color colorTextoPago = Colors.red.shade800;
            String textoPago = 'Resta: \$${carrito.saldoPendiente.toStringAsFixed(2)}';

            if (carrito.anticipo >= carrito.total && carrito.total > 0) {
              colorPago = Colors.green.shade100;
              colorTextoPago = Colors.green.shade800;
              textoPago = '¡Liquidado!';
            } else if (carrito.anticipo > 0) {
              colorPago = Colors.orange.shade100;
              colorTextoPago = Colors.orange.shade900;
              textoPago = 'Abonó: \$${carrito.anticipo.toStringAsFixed(0)} | Resta: \$${carrito.saldoPendiente.toStringAsFixed(0)}';
            }

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Franja lateral de color
                    Container(width: 8, color: _colorUrgencia(carrito.fechaEntrega)),
                    
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Encabezado: Fecha y Lugar
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    _formatearFechaAmigable(carrito.fechaEntrega),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ),
                              ],
                            ),
                            if (carrito.lugarEntrega != null && carrito.lugarEntrega!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      carrito.lugarEntrega!,
                                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            
                            const SizedBox(height: 10),
                            const Divider(height: 1),
                            const SizedBox(height: 10),

                            // Cliente y Badge de Pago
                            Text(
                              carrito.telefonoCliente,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: colorPago,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                textoPago,
                                style: TextStyle(color: colorTextoPago, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),

                            const SizedBox(height: 10),

                            // Fila de Botones de Acción
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  tooltip: 'Registrar Anticipo',
                                  icon: const Icon(Icons.payments_outlined, color: Colors.orange),
                                  onPressed: () => _dialogoAnticipo(context, provider, identificador, carrito),
                                ),
                                IconButton(
                                  tooltip: 'Agendar / Reagendar',
                                  icon: const Icon(Icons.edit_calendar, color: Colors.blue),
                                  onPressed: () => _dialogoAgendar(context, provider, identificador, carrito),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- DIÁLOGOS DE ACCIÓN ---

  void _dialogoAgendar(BuildContext context, InventarioProvider provider, String identificador, Carrito carrito) {
    DateTime? fechaSeleccionada = carrito.fechaEntrega;
    TimeOfDay? horaSeleccionada = carrito.fechaEntrega != null ? TimeOfDay.fromDateTime(carrito.fechaEntrega!) : null;
    final lugarCtrl = TextEditingController(text: carrito.lugarEntrega ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Agendar Entrega'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: lugarCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Lugar de encuentro',
                      prefixIcon: Icon(Icons.location_city),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: Text(fechaSeleccionada == null 
                      ? 'Seleccionar Día' 
                      : '${fechaSeleccionada!.day}/${fechaSeleccionada!.month}/${fechaSeleccionada!.year}'
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: fechaSeleccionada ?? DateTime.now(),
                        firstDate: DateTime.now().subtract(const Duration(days: 1)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setStateDialog(() => fechaSeleccionada = date);
                      }
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.access_time),
                    title: Text(horaSeleccionada == null 
                      ? 'Seleccionar Hora' 
                      : horaSeleccionada!.format(context)
                    ),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: horaSeleccionada ?? TimeOfDay.now(),
                      );
                      if (time != null) {
                        setStateDialog(() => horaSeleccionada = time);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () {
                  DateTime? fechaFinal;
                  if (fechaSeleccionada != null && horaSeleccionada != null) {
                    fechaFinal = DateTime(
                      fechaSeleccionada!.year,
                      fechaSeleccionada!.month,
                      fechaSeleccionada!.day,
                      horaSeleccionada!.hour,
                      horaSeleccionada!.minute,
                    );
                  }
                  
                  provider.actualizarLogistica(
                    identificador, 
                    fechaEntrega: fechaFinal, 
                    lugarEntrega: lugarCtrl.text.trim(),
                  );
                  Navigator.pop(ctx);
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        }
      ),
    );
  }

  void _dialogoAnticipo(BuildContext context, InventarioProvider provider, String identificador, Carrito carrito) {
    final montoCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registrar Anticipo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('El cliente debe \$${carrito.saldoPendiente.toStringAsFixed(2)} en total.'),
            const SizedBox(height: 15),
            TextField(
              controller: montoCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Monto recibido',
                prefixText: '\$ ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final monto = double.tryParse(montoCtrl.text) ?? 0.0;
              if (monto > 0) {
                provider.registrarAnticipo(identificador, monto);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Abonar'),
          ),
        ],
      ),
    );
  }
}