import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl =
      'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd';

  Future<double> fetchBtcPrice() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['bitcoin']['usd'].toDouble();
      } else {
        throw Exception('Failed to load BTC price');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server');
    }
  }
}
