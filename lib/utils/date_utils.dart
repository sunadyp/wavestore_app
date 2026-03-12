import 'package:flutter/material.dart';

class DateHelper {
  static DateTimeRange get semanaActual {
    DateTime hoy = DateTime.now();
    // Encuentra el lunes de esta semana
    DateTime lunes = DateTime(hoy.year, hoy.month, hoy.day).subtract(Duration(days: hoy.weekday - 1));
    return DateTimeRange(start: lunes, end: hoy);
  }
}