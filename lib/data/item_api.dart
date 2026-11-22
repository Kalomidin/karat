import 'dart:convert';
import 'dart:io';

import 'package:karat/config/api.dart';
import 'package:karat/domain/jewellery_item.dart';

class ItemApiException implements Exception {
  const ItemApiException();
}

class ItemApi {
  ItemApi({HttpClient? http, String? apiBase})
    : _http = http ?? HttpClient(),
      apiBase = _trim(apiBase ?? karatApiBase()) {
    _http.connectionTimeout = const Duration(seconds: 5);
  }

  final HttpClient _http;
  final String apiBase;

  Future<List<JewelleryItem>> list(String idToken) async {
    final request = await _http.getUrl(Uri.parse('$apiBase/item'));
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $idToken');
    final response = await request.close().timeout(const Duration(seconds: 8));
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode != 200) throw const ItemApiException();
    final decoded = jsonDecode(body);
    if (decoded is! List) throw const ItemApiException();
    return decoded.map((entry) {
      if (entry is! Map) throw const ItemApiException();
      return JewelleryItem.fromJson(entry.cast<String, Object?>());
    }).toList();
  }

  Future<List<JewelleryItem>> create(
    String idToken,
    JewelleryItem item, {
    int quantity = 1,
  }) async {
    final decoded = await _send(
      idToken,
      'POST',
      '$apiBase/item',
      _body(item, quantity: quantity),
    );
    if (decoded is! List) throw const ItemApiException();
    return decoded.map((entry) {
      if (entry is! Map) throw const ItemApiException();
      return JewelleryItem.fromJson(entry.cast<String, Object?>());
    }).toList();
  }

  Future<JewelleryItem> update(String idToken, JewelleryItem item) {
    return _write(idToken, 'PUT', '$apiBase/item/${item.id}', item);
  }

  Future<JewelleryItem> sell(String idToken, JewelleryItem item) {
    return _writeJson(idToken, 'POST', '$apiBase/item/${item.id}/sale', {
      'soldOn': item.soldOn!.utcStart,
      'soldAmount': item.soldCents! ~/ 100,
    });
  }

  Future<JewelleryItem> returnToStock(String idToken, String id) {
    return _writeJson(idToken, 'POST', '$apiBase/item/$id/return', const {});
  }

  Future<void> delete(String idToken, String id) async {
    final request = await _http.deleteUrl(Uri.parse('$apiBase/item/$id'));
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $idToken');
    final response = await request.close().timeout(const Duration(seconds: 8));
    await response.drain<void>();
    if (response.statusCode != 200) throw const ItemApiException();
  }

  Future<JewelleryItem> _write(
    String idToken,
    String method,
    String url,
    JewelleryItem item,
  ) async {
    return _writeJson(idToken, method, url, _body(item));
  }

  Future<JewelleryItem> _writeJson(
    String idToken,
    String method,
    String url,
    Map<String, Object?> body,
  ) async {
    final decoded = await _send(idToken, method, url, body);
    if (decoded is! Map) throw const ItemApiException();
    return JewelleryItem.fromJson(decoded.cast<String, Object?>());
  }

  Future<Object?> _send(
    String idToken,
    String method,
    String url,
    Map<String, Object?> body,
  ) async {
    final request = await _http.openUrl(method, Uri.parse(url));
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $idToken');
    request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    request.add(utf8.encode(jsonEncode(body)));
    final response = await request.close().timeout(const Duration(seconds: 8));
    final raw = await response.transform(utf8.decoder).join();
    if (response.statusCode != 200) throw const ItemApiException();
    if (raw.isEmpty) return null;
    return jsonDecode(raw);
  }
}

Map<String, Object?> _body(JewelleryItem item, {int? quantity}) {
  return {
    'name': item.name,
    'kind': item.kind.name,
    'metal': item.metal.name,
    'purity': item.purity,
    'weightGrams': item.weightGrams,
    'currencyId': item.currencyId,
    'cost': item.costCents ~/ 100,
    'notes': item.notes,
    'createdOn': item.createdOn.utcStart,
    if (item.imageKey.isNotEmpty) 'imageKey': item.imageKey,
    if (item.groupId.isNotEmpty) 'groupId': item.groupId,
    if (quantity != null) 'quantity': quantity,
  };
}

String _trim(String value) => value.replaceAll(RegExp(r'/+$'), '');
