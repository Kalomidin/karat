import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:karat/data/piece_photo_upload.dart';

void main() {
  test('upload sends the token and the photo bytes', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    String? authorization;
    String? putType;
    final putBody = <int>[];
    server.listen((request) async {
      if (request.uri.path == '/item/upload-url') {
        authorization = request.headers.value(HttpHeaders.authorizationHeader);
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode({
              'uploadUrl': 'http://127.0.0.1:${server.port}/put',
              'imageKey': 'items/ada/photo.jpg',
              'readUrl': 'http://127.0.0.1:${server.port}/read',
              'contentType': 'image/jpeg',
            }),
          );
        await request.response.close();
        return;
      }
      putType = request.headers.value(HttpHeaders.contentTypeHeader);
      await for (final chunk in request) {
        putBody.addAll(chunk);
      }
      request.response.statusCode = 200;
      await request.response.close();
    });

    final uploaded =
        await PiecePhotoUploader(apiBase: 'http://127.0.0.1:${server.port}')
            .upload(
              idToken: 'token',
              bytes: Uint8List.fromList([1, 2, 3]),
              contentType: 'image/jpeg',
            );

    expect(authorization, 'Bearer token');
    expect(uploaded.imageKey, 'items/ada/photo.jpg');
    expect(putType, 'image/jpeg');
    expect(putBody, [1, 2, 3]);
  });
}
