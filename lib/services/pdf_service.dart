import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/venta.dart';

class PdfService {
  static Future<void> generarYCompartirTicket(Carrito carrito) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        // roll80 es el formato estándar de impresoras térmicas (ideal para ver en celular)
        pageFormat: PdfPageFormat.roll80, 
        margin: const pw.EdgeInsets.all(15),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Encabezado
              pw.Center(
                child: pw.Text(
                  'WAVE STORE', 
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)
                ),
              ),
              pw.Center(
                child: pw.Text('Ticket de Compra', style: const pw.TextStyle(fontSize: 12)),
              ),
              pw.SizedBox(height: 15),
              
              // Datos del cliente
              pw.Text('Clienta: ${carrito.telefonoCliente}', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 10),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 5),
              
              // Lista de Artículos
              ...carrito.articulos.map((art) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Text('${art.cantidad}x ${art.productoNombre}', style: const pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Text('\$${art.subtotal.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
                    ]
                  ),
                );
              }).toList(),
              
              pw.SizedBox(height: 5),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 5),
              
              // Totales
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal:', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('\$${carrito.subtotal.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
                ]
              ),
              
              // Solo muestra el descuento si existe
              if (carrito.descuentoMonto > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Descuento:', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('-\$${carrito.descuentoMonto.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
                  ]
                ),
              
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL A PAGAR:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Text('\$${carrito.total.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ]
              ),
              
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text('¡Gracias por tu compra!', style: const pw.TextStyle(fontSize: 10)),
              ),
            ],
          );
        },
      ),
    );

    // Esto abre directamente el menú nativo para compartir (WhatsApp, Telegram, etc.)
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Ticket_WaveStore_${carrito.telefonoCliente}.pdf',
    );
  }
}