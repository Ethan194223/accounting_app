// lib/services/currency_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyService {
  final String _apiKey = "cd1bf78c5d71255e94464ff6"; // My API Key
  final String _baseUrl = "https://v6.exchangerate-api.com/v6/";

  Future<Map<String, dynamic>?> getLatestRates(String baseCurrency) async {
    final String url = "$_baseUrl$_apiKey/latest/${baseCurrency.toUpperCase()}";
    print("DEBUG: CurrencyService: Attempting to fetch rates from URL: $url");

    try {
      final response = await http.get(Uri.parse(url));
      print("DEBUG: CurrencyService: API Response Code: ${response.statusCode}");
      print("DEBUG: CurrencyService: API Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] == 'success' && data['conversion_rates'] != null) {
          print("DEBUG: CurrencyService: API call successful. Rates received.");
          return data['conversion_rates'] as Map<String, dynamic>;
        } else {
          print("DEBUG: CurrencyService: API Error in response data: ${data['error-type'] ?? 'Unknown API error in response data'}");
          return null;
        }
      } else {
        print("DEBUG: CurrencyService: HTTP Error. Status Code: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("DEBUG: CurrencyService: Network or other error during API call: $e");
      return null;
    }
  }
}

