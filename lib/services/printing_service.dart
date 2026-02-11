import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:blue_thermal_printer_plus/blue_thermal_printer_plus.dart' as blue;
import 'package:blue_thermal_printer_plus/bluetooth_device.dart' as blue_dev;
import 'package:permission_handler/permission_handler.dart';
import '../domain/entities/cobro.dart';
import '../domain/entities/sastre.dart';
import 'package:intl/intl.dart';

/// Clase envolvente para cumplir con la "API OBLIGATORIA" solicitada por el usuario.
/// Proporciona los métodos con los nombres y tipos exactos que el requerimiento exige,
/// evitando el uso de BluetoothDevice y cumpliendo con las restricciones.
class BlueThermalPrinterPlus {
  final blue.BlueThermalPrinterPlus _plugin = blue.BlueThermalPrinterPlus();

  /// Obtiene impresoras emparejadas (API OBLIGATORIA)
  Future<List<Map<String, dynamic>>> getBondedPrinters() async {
    try {
      final List<blue_dev.BluetoothDevice> devices = await _plugin.getBondedDevices();
      return devices.map((d) => d.toMap()).toList();
    } catch (e) {
      debugPrint("BlueThermalPrinterPlus wrapper: Error en getBondedPrinters: $e");
      return [];
    }
  }

  /// Conecta a una impresora mediante su dirección MAC (API OBLIGATORIA)
  Future<void> connect(String macAddress) async {
    await _plugin.connect(blue_dev.BluetoothDevice(null, macAddress));
  }

  /// Desconecta de la impresora (Nueva funcionalidad para manejo de ciclo de vida)
  Future<void> disconnect() async {
    try {
      await _plugin.disconnect();
    } catch (e) {
      debugPrint("BlueThermalPrinterPlus wrapper: Error en disconnect: $e");
    }
  }

  /// Verifica si hay una conexión activa (Nueva funcionalidad)
  Future<bool> get isConnected async {
    try {
      return await _plugin.isConnected ?? false;
    } catch (_) {
      return false;
    }
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

  /// Genera los bytes ESC/POS para la factura
  static List<int> _generateBytes({
    required Cobro cobro,
    required Sastre sastre,
    required String nombreNegocio,
  }) {
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

    String money(double v) => 'RD\$ ${v.toStringAsFixed(2)}';

    bytes += utf8.encode('Monto:     ${money(cobro.montoTotal)}\n');
    bytes += utf8.encode('Comision:  ${money(cobro.comisionMonto)}\n');


    // Separador para el neto
    bytes += utf8.encode('           ----------\n');

    // Neto Sastre en negrita (ESC E 1)
    bytes += [esc, 69, 1];
    bytes += utf8.encode('Neto Sastre: ${money(cobro.netoSastre)}\n');
    bytes += [esc, 69, 0];

    bytes += [esc, 97, 1]; // Centrado
    bytes += utf8.encode('--------------------------------\n');
    bytes += utf8.encode('GRACIAS POR PREFERIRNOS\n');
    // Mensaje de desarrollo (pequeno, centrado)
    bytes += [esc, 33, 0]; // Texto normal (tamano pequeno)
    bytes += utf8.encode('Desarrollado por TYSOFTRD\n');

    bytes += utf8.encode('\n\n');
    // Corte de papel (GS V 65 3)
    bytes += [gs, 86, 65, 3];

    // Finalizar con un reset para asegurar que el estado sea limpio
    bytes += [esc, 64];

    return bytes;
  }

  /// Genera los bytes ESC/POS para el cierre diario
  static List<int> _generateClosureBytes({
    required List<Cobro> cobros,
    required List<Sastre> sastres,
    required String nombreNegocio,
    required DateTime fecha,
  }) {
    List<int> bytes = [];
    const esc = 27;
    const gs = 29;

    // Inicializar impresora (ESC @)
    bytes += [esc, 64];

    // Texto centrado (ESC a 1)
    bytes += [esc, 97, 1];

    // Título CIERRE DEL DÍA (Negrita y tamaño doble)
    bytes += [gs, 33, 17];
    bytes += utf8.encode('CIERRE DEL DÍA\n');
    bytes += [gs, 33, 0]; // Tamaño normal

    final dateFormat = DateFormat('dd/MM/yyyy');
    bytes += utf8.encode('Fecha: ${dateFormat.format(fecha)}\n');
    bytes += utf8.encode('--------------------------------\n');

    // Alinear a la izquierda para los detalles (ESC a 0)
    bytes += [esc, 97, 0];

    bytes += utf8.encode('--- POR SASTRE ---\n');

    String money(double v) => 'RD\$ ${v.toStringAsFixed(2).padLeft(10)}';

    double totalComisionDia = 0;

    for (var sastre in sastres) {
      final sastreCobros = cobros.where((c) => c.sastreId == sastre.id).toList();
      if (sastreCobros.isEmpty) continue;

      final generado = sastreCobros.fold(0.0, (sum, c) => sum + c.montoTotal);
      final comision = sastreCobros.fold(0.0, (sum, c) => sum + c.comisionMonto);
      final neto = generado - comision;

      totalComisionDia += comision;

      bytes += utf8.encode('${sastre.nombre}\n');
      bytes += utf8.encode('Total generado: ${money(generado)}\n');
      bytes += utf8.encode('Comisión:       ${money(comision)}\n');
      bytes += utf8.encode('Neto entregado: ${money(neto)}\n');
      bytes += utf8.encode('\n');
    }

    bytes += utf8.encode('--- PROPIETARIO ---\n');
    bytes += utf8.encode('Total comisión día: ${money(totalComisionDia)}\n');

    bytes += [esc, 97, 1]; // Centrado
    bytes += utf8.encode('--------------------------------\n');
    bytes += utf8.encode('Sistema Sastrería\n');
    bytes += utf8.encode('Desarrollado por TYSOFTRD\n');

    bytes += utf8.encode('\n\n');
    // Corte de papel (GS V 65 3)
    bytes += [gs, 86, 65, 3];

    // Finalizar con un reset
    bytes += [esc, 64];

    return bytes;
  }

  /// Realiza la impresión de la factura
  static Future<bool> printInvoice({
    required Cobro cobro,
    required Sastre sastre,
    required String nombreNegocio,
  }) async {
    bool isConnected = false;
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

      // 3. Obtener dirección MAC
      String? macAddress = printers.first['address'] ?? printers.first['mac'];
      if (macAddress == null) {
        debugPrint("PrintingService: No se pudo obtener la dirección MAC.");
        return false;
      }

      // 4. Asegurar estado limpio antes de intentar conectar
      // Si ya está conectado, desconectamos primero para forzar una nueva sesión
      try {
        if (await _printer.isConnected) {
          await _printer.disconnect();
          await Future.delayed(const Duration(milliseconds: 500));
        }
      } catch (e) {
        debugPrint("PrintingService: Error durante limpieza pre-conexión: $e");
      }

      // 5. Conectar (Un job = una conexión)
      await _printer.connect(macAddress);
      isConnected = true;

      // Delay de estabilización para la JACL-P280
      await Future.delayed(const Duration(milliseconds: 1000));

      // 6. Generar contenido ESC/POS
      final bytes = _generateBytes(
        cobro: cobro,
        sastre: sastre,
        nombreNegocio: nombreNegocio,
      );

      // 7. Enviar a la impresora
      await _printer.writeBytes(bytes);

      // 8. Delay técnico para asegurar que los datos salieron del buffer del SO
      // antes de cerrar el socket físico.
      await Future.delayed(const Duration(milliseconds: 2000));

      return true;
    } catch (e) {
      debugPrint('PrintingService Error: $e');
      return false;
    } finally {
      // 9. Liberación SEGURA del canal tras imprimir (SIEMPRE)
      if (isConnected) {
        try {
          await _printer.disconnect();
          // Pequeño delay extra para que el SO libere el socket RFCOMM
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          debugPrint('PrintingService: Error al liberar conexión: $e');
        }
      }
    }
  }

  /// Realiza la impresión del cierre diario
  static Future<bool> printClosure({
    required List<Cobro> cobros,
    required List<Sastre> sastres,
    required String nombreNegocio,
    required DateTime fecha,
  }) async {
    bool isConnected = false;
    try {
      bool hasPermission = await requestPermissions();
      if (!hasPermission) return false;

      final printers = await _printer.getBondedPrinters();
      if (printers.isEmpty) return false;

      String? macAddress = printers.first['address'] ?? printers.first['mac'];
      if (macAddress == null) return false;

      if (await _printer.isConnected) {
        await _printer.disconnect();
        await Future.delayed(const Duration(milliseconds: 500));
      }

      await _printer.connect(macAddress);
      isConnected = true;
      await Future.delayed(const Duration(milliseconds: 1000));

      final bytes = _generateClosureBytes(
        cobros: cobros,
        sastres: sastres,
        nombreNegocio: nombreNegocio,
        fecha: fecha,
      );

      await _printer.writeBytes(bytes);
      await Future.delayed(const Duration(milliseconds: 2000));

      return true;
    } catch (e) {
      debugPrint('PrintingService Closure Error: $e');
      return false;
    } finally {
      if (isConnected) {
        try {
          await _printer.disconnect();
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (_) {}
      }
    }
  }
}
