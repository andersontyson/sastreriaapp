import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:blue_thermal_printer_plus/blue_thermal_printer_plus.dart' as blue;
import 'package:permission_handler/permission_handler.dart';
import '../domain/entities/cobro.dart';
import '../domain/entities/sastre.dart';
import 'package:intl/intl.dart';

/// Clase envolvente para cumplir con la "API OBLIGATORIA" solicitada por el usuario.
/// Proporciona los métodos con los nombres y tipos exactos que el requerimiento exige,
/// evitando el uso de BluetoothDevice y cumpliendo con las restricciones.
class BlueThermalPrinterPlus {
  static const _channel = MethodChannel('blue_thermal_printer_plus/methods');
  final blue.BlueThermalPrinterPlus _plugin = blue.BlueThermalPrinterPlus();

  /// Obtiene impresoras emparejadas (API OBLIGATORIA)
  Future<List<Map<String, dynamic>>> getBondedPrinters() async {
    try {
      final List? list = await _channel.invokeMethod('getBondedDevices');
      if (list == null) return [];
      return list.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      debugPrint("BlueThermalPrinterPlus wrapper: Error en getBondedPrinters: $e");
      return [];
    }
  }

  /// Conecta a una impresora mediante su dirección MAC (API OBLIGATORIA)
  Future<void> connect(String macAddress) async {
    await _channel.invokeMethod('connect', {'address': macAddress});
  }

  /// Imprime bytes (API OBLIGATORIA)
  Future<void> writeBytes(List<int> bytes) async {
    // El plugin original requiere Uint8List, hacemos la conversión aquí
    await _plugin.writeBytes(Uint8List.fromList(bytes));
  }
}

class PrintingService {
  static final _printer = BlueThermalPrinterPlus();

  /// Solicita los permisos necesarios para la impresión Bluetooth
  static Future<bool> requestPermissions() async {
    // En Android 12+ (API 31+) se necesitan BLUETOOTH_SCAN y BLUETOOTH_CONNECT
    // En versiones anteriores se necesita ACCESS_FINE_LOCATION

    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    bool hasBluetoothConnect = statuses[Permission.bluetoothConnect]?.isGranted ?? false;
    // Para Android < 12, bluetoothConnect puede no ser necesario, pero permission_handler
    // lo maneja devolviendo 'granted' si no aplica.

    return hasBluetoothConnect;
  }

  /// Realiza la impresión de la factura
  static Future<bool> printInvoice({
    required Cobro cobro,
    required Sastre sastre,
    required String nombreNegocio,
  }) async {
    try {
      // 1. Verificar permisos
      bool hasPermission = await requestPermissions();
      if (!hasPermission) {
        debugPrint("PrintingService: Permisos de Bluetooth denegados.");
        return false;
      }

      // 2. Obtener impresoras vinculadas
      final printers = await _printer.getBondedPrinters();
      if (printers.isEmpty) {
        debugPrint("PrintingService: No se encontraron impresoras vinculadas.");
        return false;
      }

      // 3. Conectar a la primera impresora disponible (requerimiento de impresión inmediata)
      String? macAddress = printers.first['address'] ?? printers.first['mac'];
      if (macAddress == null) {
        debugPrint("PrintingService: No se pudo obtener la dirección MAC.");
        return false;
      }

      await _printer.connect(macAddress);

      // 4. Generar contenido ESC/POS
      List<int> bytes = [];
      const esc = 27;
      const gs = 29;

      // Inicializar impresora (ESC @)
      bytes += [esc, 64];

      // Texto centrado (ESC a 1)
      bytes += [esc, 97, 1];

      // Nombre del negocio (Negrita y tamaño doble)
      // GS ! n (n=17 para doble ancho y alto)
      bytes += [gs, 33, 17];
      bytes += utf8.encode('$nombreNegocio\n');
      bytes += [gs, 33, 0]; // Tamaño normal

      bytes += utf8.encode('--------------------------------\n');

      // Alinear a la izquierda para los detalles (ESC a 0)
      bytes += [esc, 97, 0];

      final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
      bytes += utf8.encode('Sastre: ${sastre.nombre}\n');
      bytes += utf8.encode('Fecha:  ${dateFormat.format(cobro.fecha)}\n');

      if (cobro.cliente != null && cobro.cliente!.isNotEmpty) {
        bytes += utf8.encode('Cliente: ${cobro.cliente}\n');
      }

      bytes += utf8.encode('\n');
      bytes += utf8.encode('Trabajo: ${cobro.prenda ?? "Ajuste General"}\n');
      bytes += utf8.encode('\n');

      final currencyFormat = NumberFormat.currency(locale: 'es_DO', symbol: 'RD\$ ');
      bytes += utf8.encode('Monto:     ${currencyFormat.format(cobro.montoTotal)}\n');
      bytes += utf8.encode('Comisión:  ${currencyFormat.format(cobro.comisionMonto)}\n');

      // Separador para el neto
      bytes += utf8.encode('           ----------\n');

      // Neto Sastre en negrita (ESC E 1)
      bytes += [esc, 69, 1];
      bytes += utf8.encode('Neto Sastre: ${currencyFormat.format(cobro.netoSastre)}\n');
      bytes += [esc, 69, 0];

      bytes += [esc, 97, 1]; // Centrado
      bytes += utf8.encode('--------------------------------\n');
      bytes += utf8.encode('GRACIAS POR SU PREFERENCIA\n\n\n');

      // Corte de papel (GS V 65 3)
      bytes += [gs, 86, 65, 3];

      // 5. Enviar a la impresora
      await _printer.writeBytes(bytes);

      return true;
    } catch (e) {
      debugPrint('PrintingService Error: $e');
      return false;
    }
  }
}
