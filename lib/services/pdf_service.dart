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

    // Intentamos cargar el logo, si no existe usamos un icono de texto
    pw.Widget logo;
    try {
      final ByteData logoData = await rootBundle.load('assets/logo.jog');
      final Uint8List logoBytes = logoData.buffer.asUint8List();
      logo = pw.Image(pw.MemoryImage(logoBytes), width: 45);
    } catch (e) {
      logo = pw.Text("", style: const pw.TextStyle(fontSize: 30));
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: pw.EdgeInsets.zero, // Quitamos margen para las ondas
        build: (pw.Context context) {
          return pw.Column(
            children: [
              // Borde ondulado superior (Simulado con fondo rosa)
              pw.Container(
                height: 10,
                width: double.infinity,
                decoration: pw.BoxDecoration(color: rosaPastel),
              ),
              
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                child: pw.Column(
                  children: [
                    // Encabezado con Logo y Estilo
                    pw.Center(child: logo),
                    pw.SizedBox(height: 5),
                    pw.Text('WAVE STORE', 
                      style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: rosaFuerte)),
                    pw.Text('Ticket de Compra', style: pw.TextStyle(fontSize: 10, color: grisOscuro)),
                    
                    pw.SizedBox(height: 10),
                    pw.Divider(color: rosaFuerte, thickness: 0.5),
                    
                    // Info Cliente con Iconos
                    pw.Row(
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Cliente: ${carrito.telefonoCliente}', 
                              style: pw.TextStyle(fontSize: 9, color: grisOscuro)),
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
                      padding: const pw.EdgeInsets.all(3),
                      color: rosaPastel,
                      child: pw.Text('PRODUCTOS', 
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: rosaFuerte)),
                    ),
                    pw.SizedBox(height: 5),

                    // Lista de Artículos
                    ...carrito.articulos.map((art) {
                      return pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 2),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('${art.cantidad}x ${art.productoNombre}', 
                              style: const pw.TextStyle(fontSize: 9)),
                            pw.Text('\$${art.subtotal.toStringAsFixed(2)}', 
                              style: const pw.TextStyle(fontSize: 9)),
                          ],
                        ),
                      );
                    }).toList(),

                    pw.SizedBox(height: 5),
                    pw.Divider(color: rosaPastel, borderStyle: pw.BorderStyle.dashed),
                    
                    // Totales
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Subtotal:', style: const pw.TextStyle(fontSize: 9)),
                        pw.Text('\$${carrito.subtotal.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 9)),
                      ]
                    ),
                    if (carrito.descuentoMonto > 0)
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Descuento:', style: const pw.TextStyle(fontSize: 9)),
                          pw.Text('-\$${carrito.descuentoMonto.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 9)),
                        ]
                      ),

                    pw.SizedBox(height: 10),
                    
                    // Cuadro de Total a Pagar
                    pw.Container(
                      padding: const pw.EdgeInsets.all(6),
                      decoration: pw.BoxDecoration(
                        color: rosaPastel,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('TOTAL A PAGAR', 
                            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: rosaFuerte)),
                          pw.Text('\$${carrito.total.toStringAsFixed(2)}', 
                            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: rosaFuerte)),
                        ]
                      ),
                    ),

                    pw.SizedBox(height: 20),
                    pw.Text('¡Gracias por tu compra!', 
                      style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic, color: rosaFuerte)),
                    pw.Text('', style: pw.TextStyle(fontSize: 10, color: rosaFuerte)),
                    pw.Text('Vuelve pronto', style: pw.TextStyle(fontSize: 8, color: grisOscuro)),
                    
                    pw.SizedBox(height: 10),
                    pw.Text('N° Ticket: #WAVE-${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}', 
                      style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                  ],
                ),
              ),

              // Borde ondulado inferior
              pw.Container(
                height: 10,
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
      filename: 'Ticket_WaveStore_${carrito.telefonoCliente}.pdf',
    );
  }
}