import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:intl/intl.dart';
import '../domain/entities/cobro.dart';
import '../domain/entities/configuracion.dart';
import '../domain/entities/sastre.dart';

/// Service to handle Bluetooth thermal printing for receipts.
///
/// We chose 'blue_thermal_printer' because it is one of the most stable and
/// simple packages for Android thermal printing. It supports standard ESC/POS
/// commands and handles Bluetooth connectivity natively for classic printers,
/// which are common in retail/service environments like tailoring shops.
class PrintingService {
  BlueThermalPrinter get _bluetooth => BlueThermalPrinter.instance;

  /// Attempts to print an invoice for a specific [cobro].
  /// Returns true if successful, false otherwise.
  Future<bool> printInvoice({
    required Configuracion config,
    required Sastre sastre,
    required Cobro cobro,
  }) async {
    try {
      bool? isConnected = await _bluetooth.isConnected;

      if (isConnected != true) {
        List<BluetoothDevice> devices = await _bluetooth.getBondedDevices();
        if (devices.isEmpty) {
          return false;
        }
        // Automatically try to connect to the first paired device
        // In a more complex app, we might want a printer selector.
        try {
          await _bluetooth.connect(devices.first);
        } catch (e) {
          return false;
        }
      }

      final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm');
      final String fechaStr = formatter.format(cobro.fecha);
      final currencyFormat = NumberFormat.currency(symbol: r'RD$ ', decimalDigits: 2);

      // --- TICKET FORMATTING (ESC/POS) ---

      _bluetooth.printCustom("--------------------------------", 1, 1);
      _bluetooth.printCustom(config.nombreNegocio.toUpperCase(), 2, 1);
      _bluetooth.printCustom("--------------------------------", 1, 1);

      _bluetooth.printLeftRight("Sastre:", sastre.nombre, 1);
      _bluetooth.printLeftRight("Fecha:", fechaStr, 1);
      _bluetooth.printNewLine();

      if (cobro.prenda != null && cobro.prenda!.isNotEmpty) {
        _bluetooth.printCustom("Trabajo: ${cobro.prenda}", 1, 0);
      }

      _bluetooth.printLeftRight("Monto:", currencyFormat.format(cobro.montoTotal), 1);
      _bluetooth.printLeftRight("Comision:", currencyFormat.format(cobro.comisionMonto), 1);
      _bluetooth.printLeftRight("Neto Sastre:", currencyFormat.format(cobro.netoSastre), 1);

      _bluetooth.printNewLine();
      _bluetooth.printCustom("--------------------------------", 1, 1);
      _bluetooth.printCustom("GRACIAS", 2, 1);
      _bluetooth.printCustom("--------------------------------", 1, 1);

      // Feed and cut
      _bluetooth.printNewLine();
      _bluetooth.printNewLine();
      _bluetooth.printNewLine();
      _bluetooth.paperCut();

      return true;
    } catch (e) {
      // We don't want to crash the app if printing fails
      return false;
    }
  }
}
