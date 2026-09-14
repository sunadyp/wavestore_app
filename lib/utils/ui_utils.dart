import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventario_provider.dart';
import '../models/producto.dart';

class UIUtils {
  // Función normalizadora idéntica a la del backend
  static String _normalizarIdentificador(String texto) {
    String t = texto.trim().toLowerCase();
    t = t.replaceAll(RegExp(r'[áäâà]'), 'a');
    t = t.replaceAll(RegExp(r'[éëêè]'), 'e');
    t = t.replaceAll(RegExp(r'[íïîì]'), 'i');
    t = t.replaceAll(RegExp(r'[óöôò]'), 'o');
    t = t.replaceAll(RegExp(r'[úüûù]'), 'u');
    return t;
  }

  // Diálogo para confirmar eliminación
  static Future<bool?> confirmarEliminacion(BuildContext context, String nombre) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('¿Eliminar producto?'),
        content: Text('¿Estás seguro de que quieres eliminar "$nombre"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent, 
              foregroundColor: Colors.white
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    );
  }

  // --- Diálogo para apartar/vender producto y mandarlo a un Carrito ---
  static Future<Map<String, dynamic>?> mostrarDialogoVenta(BuildContext context, Producto producto) {
    final qtyCtrl = TextEditingController(text: '1');
    final telefonoCtrl = TextEditingController();
    
    // Obtenemos las cuentas activas para el menú desplegable
    final provider = Provider.of<InventarioProvider>(context, listen: false);
    final carritosActivos = provider.carritosActivos;
    // Las llaves ya vienen normalizadas desde el provider
    final telefonosNormalizados = carritosActivos.keys.toList();
    
    // Variable para reaccionar a lo que el usuario escribe o selecciona
    String telefonoActual = '';

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          
          // Normalizamos el texto en tiempo real para ver si hace match con algún carrito
          final textoNormalizado = _normalizarIdentificador(telefonoActual);
          final bool existeCuenta = telefonosNormalizados.contains(textoNormalizado);

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: Text('Apartar ${producto.nombre}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  
                  // Mostrar dropdown solo si hay carritos activos
                  if (telefonosNormalizados.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Seleccionar cuenta activa',
                        prefixIcon: Icon(Icons.arrow_drop_down_circle),
                      ),
                      // El dropdown utiliza el string normalizado internamente
                      value: existeCuenta ? textoNormalizado : null,
                      items: telefonosNormalizados.map((key) {
                        // Pero a la vista se muestra el nombre original registrado
                        final nombreOriginal = carritosActivos[key]!.telefonoCliente;
                        return DropdownMenuItem(
                          value: key,
                          child: Text(nombreOriginal),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          final nombreOriginal = carritosActivos[val]!.telefonoCliente;
                          telefonoCtrl.text = nombreOriginal;
                          setStateDialog(() {
                            telefonoActual = nombreOriginal;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    const Text('O ingresa un número/nombre nuevo:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 5),
                  ],
              
                  TextField(
                    controller: telefonoCtrl,
                    keyboardType: TextInputType.text, 
                    autofocus: telefonosNormalizados.isEmpty, 
                    decoration: const InputDecoration(
                      labelText: 'Teléfono, Nombre o @usuario', 
                      prefixIcon: Icon(Icons.person), 
                    ),
                    onChanged: (val) {
                      setStateDialog(() {
                        telefonoActual = val;
                      });
                    },
                  ),
                  
                  // Alerta visual si la cuenta ya está activa
                  if (existeCuenta)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.red, size: 16),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Esta cuenta ya está activa. Se añadirán los productos a esa misma cuenta.',
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
              
                  const SizedBox(height: 10),
                  TextField(
                    controller: qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Cantidad a apartar',
                      suffixText: 'un.',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  final qty = int.tryParse(qtyCtrl.text);
                  // Solo hacemos el trim normal aquí. El Provider se encarga del resto.
                  final telefono = telefonoCtrl.text.trim();
                  
                  if (telefono.isNotEmpty && qty != null && qty > 0) {
                    Navigator.pop(ctx, {'telefono': telefono, 'cantidad': qty});
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ingresa un identificador y cantidad válidos')),
                    );
                  }
                },
                child: const Text('AGREGAR AL CARRITO'),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- Diálogo para reabastecer y calcular costo promedio ---
  static Future<Map<String, dynamic>?> mostrarDialogoReabastecer(BuildContext context, Producto producto) {
    final qtyCtrl = TextEditingController();
    final costoCtrl = TextEditingController(text: producto.costo.toString()); 

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text('Reabastecer ${producto.nombre}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ingresa las nuevas unidades y su costo individual. La app calculará el costo promedio automáticamente.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Unidades entrantes',
                  suffixText: 'un.',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: costoCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Costo unitario (De esta tanda)',
                  prefixText: '\$ ',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final qty = int.tryParse(qtyCtrl.text);
              final costo = double.tryParse(costoCtrl.text);
              
              if (qty != null && qty > 0 && costo != null && costo >= 0) {
                Navigator.pop(ctx, {'cantidad': qty, 'costo': costo});
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ingresa cantidades y costos válidos')),
                );
              }
            },
            child: const Text('AGREGAR STOCK'),
          ),
        ],
      ),
    );
  }
}