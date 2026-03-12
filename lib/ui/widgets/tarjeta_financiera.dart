import 'package:flutter/material.dart';

class TarjetaFinanciera extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final Color colorFondo;
  final Color colorTexto;
  final bool esPequena;

  const TarjetaFinanciera({
    super.key,
    required this.titulo,
    required this.valor,
    required this.icono,
    required this.colorFondo,
    required this.colorTexto,
    this.esPequena = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(fontSize: esPequena ? 14 : 16, color: colorTexto.withOpacity(0.8)),
                ),
              ),
              Icon(icono, color: colorTexto, size: esPequena ? 24 : 28),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            valor,
            style: TextStyle(fontSize: esPequena ? 20 : 28, fontWeight: FontWeight.bold, color: colorTexto),
          ),
        ],
      ),
    );
  }
}