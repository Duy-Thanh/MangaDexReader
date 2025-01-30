import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

class NetworkHelper {
  static Future<bool> isInternetAvailable() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      return false;
    }

    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  static Future<bool> isVpnActive() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.any,
      );

      return interfaces.any((interface) {
        return interface.name.toLowerCase().contains('tun') ||
            interface.name.toLowerCase().contains('ppp') ||
            interface.name.toLowerCase().contains('vpn');
      });
    } catch (e) {
      print('Error checking VPN status: $e');
      return false;
    }
  }

  static Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.mangadex.org/ping'),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Network test error: $e');
      return false;
    }
  }
}
