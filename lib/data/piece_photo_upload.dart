import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:karat/config/api.dart';

class UploadedPiecePhoto {
  const UploadedPiecePhoto({required this.imageKey, required this.readUrl});

  final String imageKey;
  final String readUrl;
}

class PiecePhotoUploadException implements Exception {
  const PiecePhotoUploadException();
}

class PiecePhotoUploader {
  PiecePhotoUploader({HttpClient? http, String? apiBase})
    : _http = http ?? HttpClient(),
      apiBase = _trim(apiBase ?? karatApiBase());

  final HttpClient _http;
  final String apiBase;

  Future<UploadedPiecePhoto> upload({
    required String idToken,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final ticket = await _ticket(idToken, contentType);
    await _put(ticket.uploadUrl, bytes, ticket.contentType);
    return UploadedPiecePhoto(
      imageKey: ticket.imageKey,
      readUrl: ticket.readUrl,
    );
  }

  Future<_Ticket> _ticket(String idToken, String contentType) async {
    final request = await _http.postUrl(Uri.parse('$apiBase/item/upload-url'));
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $idToken');
    request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    request.add(utf8.encode(jsonEncode({'contentType': contentType})));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode != 200) throw const PiecePhotoUploadException();
    final json = jsonDecode(body);
    if (json is! Map) throw const PiecePhotoUploadException();
    final uploadUrl = json['uploadUrl'];
    final imageKey = json['imageKey'];
    final readUrl = json['readUrl'];
    final signedType = json['contentType'];
    if (uploadUrl is! String ||
        imageKey is! String ||
        imageKey.isEmpty ||
        readUrl is! String ||
        signedType is! String) {
      throw const PiecePhotoUploadException();
    }
    return _Ticket(uploadUrl, imageKey, readUrl, signedType);
  }

  Future<void> _put(String url, Uint8List bytes, String contentType) async {
    final request = await _http.putUrl(Uri.parse(url));
    request.headers.set(HttpHeaders.contentTypeHeader, contentType);
    request.contentLength = bytes.length;
    request.add(bytes);
    final response = await request.close();
    await response.drain<void>();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const PiecePhotoUploadException();
    }
  }
}

class _Ticket {
  const _Ticket(this.uploadUrl, this.imageKey, this.readUrl, this.contentType);

  final String uploadUrl;
  final String imageKey;
  final String readUrl;
  final String contentType;
}

String _trim(String value) {
  return value.replaceAll(RegExp(r'/+$'), '');
}

String contentTypeForPhoto(String name, String? mimeType) {
  if (mimeType == 'image/jpeg' ||
      mimeType == 'image/png' ||
      mimeType == 'image/webp') {
    return mimeType!;
  }
  final lower = name.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  return 'image/jpeg';
}

String extensionForPhoto(String contentType) {
  return switch (contentType) {
    'image/png' => '.png',
    'image/webp' => '.webp',
    _ => '.jpg',
  };
}
