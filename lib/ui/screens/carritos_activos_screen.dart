import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/inventario_provider.dart';
import '../../services/pdf_service.dart';
import '../../services/whatsapp_service.dart';
import '../../models/venta.dart';

class CarritosActivosScreen extends StatefulWidget {
  const CarritosActivosScreen({super.key});

  @override
  State<CarritosActivosScreen> createState() => _CarritosActivosScreenState();
}

class _CarritosActivosScreenState extends State<CarritosActivosScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apartados Activos'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por teléfono, nombre o @usuario...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          Expanded(
            child: Consumer<InventarioProvider>(
              builder: (context, provider, child) {
                final carritos = provider.carritosActivos;

                final carritosFiltrados = carritos.entries.where((entry) {
                  final cliente = entry.key.toLowerCase();

                  return cliente.contains(
                    _searchQuery.toLowerCase(),
                  );
                }).toList();

                if (carritosFiltrados.isEmpty) {
                  return Center(
                    child: Text(
                      _searchQuery.isEmpty
                          ? 'No hay carritos activos en este momento.'
                          : 'No se encontraron apartados para "$_searchQuery".',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: carritosFiltrados.length,
                  itemBuilder: (context, index) {
                    final entry = carritosFiltrados[index];
                    final identificadorCliente = entry.key;
                    final carrito = entry.value;
                    final bool esDeConcept = carrito.articulos.isNotEmpty && carrito.articulos.first.origenConcept;

                    return Card(
                      key: ValueKey(identificadorCliente),
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ExpansionTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Icon(
                            Icons.shopping_cart,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          'Clienta: $identificadorCliente',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'Total: \$${carrito.total.toStringAsFixed(2)} | '
                          'Artículos: ${carrito.articulos.length}',
                        ),
                        children: [
                          const Divider(),

                          ...carrito.articulos.map(
                            (articulo) => Dismissible(
                              key: ValueKey('${identificadorCliente}_${articulo.productoId}_${articulo.origenConcept}'), // <-- Ajuste de llave
                              direction: DismissDirection.endToStart,
                              background: Container(
                                color: Colors.red.shade400,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20.0),
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              confirmDismiss: (direction) async {
                                return await showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('¿Quitar producto?'),
                                    content: Text('Se devolverán ${articulo.cantidad} unidades de "${articulo.productoNombre}" al inventario.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text('No'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('Sí, quitar'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              onDismissed: (direction) {
                                provider.eliminarArticuloDeCarrito(identificadorCliente, articulo);
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${articulo.productoNombre} devuelto al inventario'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: ListTile(
                                dense: true,
                                title: Text(articulo.productoNombre),
                                subtitle: Text(articulo.origenConcept ? 'Concept Store' : 'Inventario Principal', style: const TextStyle(fontSize: 10)),
                                trailing: Text(
                                  '${articulo.cantidad} x \$${articulo.precioUnitario.toStringAsFixed(2)}',
                                ),
                              ),
                            ),
                          ),

                          const Divider(),

                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Subtotal: \$${carrito.subtotal.toStringAsFixed(2)}',
                                    ),

                                    if (carrito.descuentoMonto > 0)
                                      Text(
                                        carrito.descuentoEsPorcentaje
                                            ? 'Descuento (${carrito.descuentoValor.toInt()}%): -\$${carrito.descuentoMonto.toStringAsFixed(2)}'
                                            : 'Descuento: -\$${carrito.descuentoMonto.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: Colors.red,
                                        ),
                                      ),

                                    if (carrito.cargoExtra > 0)
                                      Text(
                                        '${carrito.conceptoCargoExtra}: +\$${carrito.cargoExtra.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),

                                    const SizedBox(height: 4),

                                    Text(
                                      'Total a cobrar: \$${carrito.total.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),

                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      icon: const Icon(
                                        Icons.local_offer,
                                        size: 18,
                                      ),
                                      label: const Text('Descuento'),
                                      onPressed: () {
                                        _mostrarDialogoDescuento(
                                          context,
                                          provider,
                                          identificadorCliente,
                                          carrito,
                                        );
                                      },
                                    ),

                                    TextButton.icon(
                                      icon: const Icon(
                                        Icons.add_box,
                                        size: 18,
                                      ),
                                      label: const Text('Cargo Extra'),
                                      onPressed: () {
                                        _mostrarDialogoCargoExtra(
                                          context,
                                          provider,
                                          identificadorCliente,
                                          carrito,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4.0,
                              vertical: 12.0,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(15),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceEvenly,
                              children: [
                                // BOTÓN CANCELAR
                                IconButton(
                                  tooltip:
                                      'Cancelar y devolver inventario',
                                  icon: const Icon(
                                    Icons.remove_shopping_cart,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    _confirmarCancelacion(
                                      context,
                                      provider,
                                      identificadorCliente,
                                    );
                                  },
                                ),

                                // BOTÓN WHATSAPP
                                IconButton(
                                  tooltip: 'Abrir chat de WhatsApp',
                                  icon: const Icon(
                                    Icons.chat,
                                    color: Colors.green,
                                  ),
                                  onPressed: () async {
                                    try {
                                      await WhatsappService.abrirChat(
                                        carrito.telefonoCliente,
                                      );
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'No se pudo abrir WhatsApp: $e',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),

                                // BOTÓN PDF
                                if (!esDeConcept)
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.blue,
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                    ),
                                    icon: const Icon(Icons.picture_as_pdf),
                                    label: const Text('PDF'),
                                    onPressed: () async {
                                      await PdfService.generarYCompartirTicket(carrito);
                                    },
                                  ),

                                // BOTÓN COBRAR
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                  ),
                                  icon: const Icon(Icons.check),
                                  label: const Text('Cobrar'),
                                  onPressed: () {
                                    _confirmarCobro(
                                      context,
                                      provider,
                                      identificadorCliente,
                                      carrito, 
                                      esDeConcept, // 🚀 LE PASAMOS LA REGLA
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 🚀 NUEVO CUADRO DE CONFIRMACIÓN CON SELECTOR DE TARJETA/EFECTIVO
  void _confirmarCobro(
    BuildContext context,
    InventarioProvider provider,
    String identificador,
    Carrito carrito,
    bool esDeConcept, // 🚀 Recibimos si es de la concept
  ) {
    bool pagoConTarjeta = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          final double comisionBase = carrito.total * 0.035;
          final double ivaComision = comisionBase * 0.16;
          final double totalComision = comisionBase + ivaComision;
          final double ingresoNeto = carrito.total - totalComision;

          return AlertDialog(
            title: const Text('Confirmar Cobro', textAlign: TextAlign.center),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🚀 SOLO MUESTRA LAS TARJETAS SI ES DE LA CONCEPT STORE
                if (esDeConcept) ...[
                  const Text('Selecciona el método de pago:', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Efectivo / Transf.')),
                          selected: !pagoConTarjeta,
                          selectedColor: Colors.green.shade100,
                          onSelected: (val) => setStateDialog(() => pagoConTarjeta = false),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Tarjeta')),
                          selected: pagoConTarjeta,
                          selectedColor: Colors.blue.shade100,
                          onSelected: (val) => setStateDialog(() => pagoConTarjeta = true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
                
                // VISTA PREVIA DEL COBRO
                if (!pagoConTarjeta)
                  Column(
                    children: [
                      Text(
                        'Total a cobrar: \$${carrito.total.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        esDeConcept ? 'Entrará íntegro a caja (Sin comisión).' : 'Venta de Inventario Principal',
                        style: const TextStyle(fontSize: 12, color: Colors.green),
                      ),
                    ],
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('El cliente paga: \$${carrito.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Comisión (3.5%): -\$${comisionBase.toStringAsFixed(2)}', style: const TextStyle(color: Colors.red, fontSize: 13)),
                        Text('IVA Com. (16%): -\$${ivaComision.toStringAsFixed(2)}', style: const TextStyle(color: Colors.red, fontSize: 13)),
                        const Divider(),
                        Text(
                          'Ingreso neto a caja: \$${ingresoNeto.toStringAsFixed(2)}', 
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 15)
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  provider.cobrarCarrito(
                    identificador,
                    pagoConTarjeta: pagoConTarjeta,
                  );
                  Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Venta cobrada con éxito. Caja actualizada.')),
                    );
                  }
                },
                child: const Text('Confirmar Pago'),
              ),
            ],
          );
        },
      ),
    );
  }

  // (Los métodos _mostrarDialogoDescuento, _mostrarDialogoCargoExtra y _confirmarCancelacion quedan igual que antes)
  void _mostrarDialogoDescuento(
    BuildContext context,
    InventarioProvider provider,
    String identificador,
    Carrito carrito,
  ) {
    final ctrl = TextEditingController(
      text: carrito.descuentoValor > 0
          ? carrito.descuentoValor.toString()
          : '',
    );

    bool esPorcentaje = carrito.descuentoEsPorcentaje;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Aplicar Descuento'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: const Text('\$ Monto'),
                      selected: !esPorcentaje,
                      onSelected: (val) {
                        setStateDialog(() {
                          esPorcentaje = false;
                        });
                      },
                    ),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      label: const Text('% Porcentaje'),
                      selected: esPorcentaje,
                      onSelected: (val) {
                        setStateDialog(() {
                          esPorcentaje = true;
                        });
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                TextField(
                  controller: ctrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: esPorcentaje
                        ? 'Porcentaje de descuento'
                        : 'Monto a descontar',
                    prefixText: esPorcentaje ? '' : '\$ ',
                    suffixText: esPorcentaje ? '%' : '',
                  ),
                  autofocus: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  final valor = double.tryParse(ctrl.text) ?? 0.0;

                  provider.aplicarDescuentoACarrito(
                    identificador,
                    valor,
                    esPorcentaje,
                  );

                  Navigator.pop(ctx);
                },
                child: const Text('Aplicar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _mostrarDialogoCargoExtra(
    BuildContext context,
    InventarioProvider provider,
    String identificador,
    Carrito carrito,
  ) {
    final montoCtrl = TextEditingController(
      text: carrito.cargoExtra > 0
          ? carrito.cargoExtra.toString()
          : '',
    );

    final conceptoCtrl = TextEditingController(
      text: carrito.cargoExtra > 0
          ? carrito.conceptoCargoExtra
          : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Agregar Cargo Extra'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ingresa el concepto y el monto adicional (ej. Envío).',
            ),
            const SizedBox(height: 15),

            TextField(
              controller: conceptoCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Concepto (Ej. Envío, Envoltura)',
                prefixIcon: Icon(Icons.edit),
              ),
              autofocus: true,
            ),

            const SizedBox(height: 10),

            TextField(
              controller: montoCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Monto del cargo',
                prefixText: '\$ ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final valor = double.tryParse(montoCtrl.text) ?? 0.0;
              final concepto = conceptoCtrl.text.trim();

              provider.aplicarCargoExtraACarrito(
                identificador,
                valor,
                concepto,
              );

              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _confirmarCancelacion(
    BuildContext context,
    InventarioProvider provider,
    String identificador,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cancelar apartado?'),
        content: const Text(
          'Los productos regresarán a su inventario correspondiente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              provider.cancelarCarrito(
                identificador,
              );

              Navigator.pop(ctx);
            },
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
  }
}