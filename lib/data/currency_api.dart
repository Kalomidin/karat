import 'dart:convert';
import 'dart:io';

import 'package:karat/config/api.dart';
import 'package:karat/domain/currency.dart';

class CurrencyApi {
  CurrencyApi({HttpClient? http, String? apiBase})
    : _http = http ?? HttpClient(),
      apiBase = (apiBase ?? karatApiBase()).replaceAll(RegExp(r'/+$'), '') {
    _http.connectionTimeout = const Duration(seconds: 5);
  }

  final HttpClient _http;
  final String apiBase;

  Future<List<ShopCurrency>> list() async {
    final request = await _http.getUrl(Uri.parse('$apiBase/currency'));
    final response = await request.close().timeout(const Duration(seconds: 8));
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode != 200) {
      throw const FormatException('currencies');
    }
    final decoded = jsonDecode(body);
    if (decoded is! List || decoded.isEmpty) {
      throw const FormatException('currencies');
    }
    return decoded.map((entry) {
      if (entry is! Map) throw const FormatException('currencies');
      final id = entry['id'];
      final code = entry['code'];
      final name = entry['name'];
      if (id is! String ||
          id.isEmpty ||
          code is! String ||
          code.isEmpty ||
          name is! String) {
        throw const FormatException('currencies');
      }
      return ShopCurrency(id: id, code: code, name: name);
    }).toList();
  }
}
