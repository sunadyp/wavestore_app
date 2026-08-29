import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/venta.dart';

class PdfService {
  static Future<void> generarYCompartirTicket(Carrito carrito) async {
    final pdf = pw.Document();

    // Colores del diseño de Wave Store
    final rosaFuerte = PdfColor.fromHex('#D81B60');
    final rosaPastel = PdfColor.fromHex('#FCE4EC');
    final grisOscuro = PdfColor.fromHex('#424242');

    // 🚀 CORRECCIÓN: Estaba mal escrito el formato de la imagen (.jog -> .jpg)
    pw.Widget logo;
    try {
      final ByteData logoData = await rootBundle.load('assets/logo.jpg');
      final Uint8List logoBytes = logoData.buffer.asUint8List();
      logo = pw.Image(pw.MemoryImage(logoBytes), width: 55); // Un poco más grande para que destaque
    } catch (e) {
      logo = pw.Text("WAVE", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: rosaFuerte));
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: pw.EdgeInsets.zero, // Quitamos margen para el diseño de borde a borde
        build: (pw.Context context) {
          return pw.Column(
            children: [
              // Borde superior (Simulado con fondo rosa)
              pw.Container(
                height: 12,
                width: double.infinity,
                decoration: pw.BoxDecoration(color: rosaPastel),
              ),
              
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: pw.Column(
                  children: [
                    // Encabezado con Logo y Estilo
                    pw.Center(child: logo),
                    pw.SizedBox(height: 6),
                    pw.Text('WAVE STORE', 
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: rosaFuerte, letterSpacing: 1.5)),
                    pw.Text('Ticket de Compra', style: pw.TextStyle(fontSize: 11, color: grisOscuro)),
                    
                    pw.SizedBox(height: 12),
                    pw.Divider(color: rosaFuerte, thickness: 0.5),
                    pw.SizedBox(height: 4),
                    
                    // Info Cliente
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Cliente: ${carrito.telefonoCliente}', 
                              style: pw.TextStyle(fontSize: 10, color: grisOscuro, fontWeight: pw.FontWeight.bold)),
                            pw.SizedBox(height: 2),
                            pw.Text('Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}', 
                              style: pw.TextStyle(fontSize: 9, color: grisOscuro)),
                          ],
                        ),
                      ],
                    ),
                    
                    pw.SizedBox(height: 12),
                    
                    // Franja de Productos
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                      color: rosaPastel,
                      child: pw.Text('CANT.   PRODUCTO   -   SUBTOTAL', 
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: rosaFuerte)),
                    ),
                    pw.SizedBox(height: 8),

                    // Lista de Artículos
                    ...carrito.articulos.map((art) {
                      return pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 6),
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Expanded(
                              child: pw.Text('${art.cantidad}x ${art.productoNombre}', 
                                style: const pw.TextStyle(fontSize: 10)),
                            ),
                            pw.Text('\$${art.subtotal.toStringAsFixed(2)}', 
                              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                      );
                    }),

                    pw.SizedBox(height: 6),
                    pw.Divider(color: rosaPastel, borderStyle: pw.BorderStyle.dashed),
                    pw.SizedBox(height: 6),
                    
                    // Totales (Subtotal)
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Subtotal:', style: const pw.TextStyle(fontSize: 10)),
                        pw.Text('\$${carrito.subtotal.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
                      ]
                    ),
                    
                    // Descuento (Si aplica)
                    if (carrito.descuentoMonto > 0)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 4),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Descuento:', style: const pw.TextStyle(fontSize: 10)),
                            pw.Text('-\$${carrito.descuentoMonto.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
                          ]
                        ),
                      ),
                      
                    // Cargo Extra Personalizado
                    if (carrito.cargoExtra > 0)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 4),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('${carrito.conceptoCargoExtra}:', style: const pw.TextStyle(fontSize: 10)),
                            pw.Text('+\$${carrito.cargoExtra.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
                          ]
                        ),
                      ),

                    pw.SizedBox(height: 12),
                    
                    // Cuadro de Total a Pagar
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      decoration: pw.BoxDecoration(
                        color: rosaPastel,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('TOTAL', 
                            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: rosaFuerte)),
                          pw.Text('\$${carrito.total.toStringAsFixed(2)}', 
                            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: rosaFuerte)),
                        ]
                      ),
                    ),

                    pw.SizedBox(height: 24),
                    pw.Text('¡Gracias por tu compra!', 
                      style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic, color: rosaFuerte, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    // Espacio para redes sociales
                    pw.Text('@wave_store', style: pw.TextStyle(fontSize: 10, color: grisOscuro)),
                    
                    pw.SizedBox(height: 16),
                    pw.Text('N° Ticket: #WV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}', 
                      style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                  ],
                ),
              ),

              // Borde inferior
              pw.Container(
                height: 12,
                width: double.infinity,
                decoration: pw.BoxDecoration(color: rosaPastel),
              ),
            ],
          );
        },
      ),
    );

    // Mantiene la funcionalidad de compartir directamente
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Ticket_WaveStore_${carrito.telefonoCliente.replaceAll(" ", "_")}.pdf', // Limpiamos espacios en el nombre del archivo
    );
  }
}