import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:karat/auth/auth_client.dart';
import 'package:karat/data/item_api.dart';
import 'package:karat/domain/currency.dart';
import 'package:karat/domain/day.dart';
import 'package:karat/domain/jewellery_item.dart';
import 'package:karat/state/karat_controller.dart';

import 'support/fakes.dart';

void main() {
  test('a reachable server replaces the local book', () async {
    final inventory = MemoryInventory();
    inventory.books['ada'] = [_localPiece('local')];
    final server = await _server(status: 200, body: [_remoteJson('server')]);
    addTearDown(server.close);

    final controller = _controller(inventory, server);
    await controller.bootstrap();

    expect(controller.items.single.id, 'server');
    expect(controller.items.single.currencyId, somoniCurrencyId);
    expect(controller.items.single.costCents, 1000);
    expect(inventory.books['ada']!.single.currencyId, somoniCurrencyId);
  });

  test('saving a piece stores the server row', () async {
    final inventory = MemoryInventory();
    final server = await _recordingServer();
    addTearDown(server.close);

    final controller = _controller(inventory, server.server);
    await controller.bootstrap();
    final saved = await controller.saveItem(_localPiece('phone-only'));

    expect(saved, isNull);
    expect(controller.items.single.id, 'server-id');
    expect(inventory.books['ada']!.single.id, 'server-id');
    final post = server.requests.singleWhere((call) => call.method == 'POST');
    final body = jsonDecode(post.body) as Map<String, Object?>;
    expect(body['name'], 'Local ring');
    expect(body['currencyId'], dollarCurrencyId);
    expect(body['cost'], 10);
  });

  test('a failed server leaves the local book', () async {
    final inventory = MemoryInventory();
    inventory.books['ada'] = [_localPiece('local')];
    final server = await _server(status: 500, body: {'error': 'internal'});
    addTearDown(server.close);

    final controller = _controller(inventory, server);
    await controller.bootstrap();

    expect(controller.items.single.id, 'local');
    expect(inventory.books['ada']!.single.id, 'local');
  });
}

KaratController _controller(MemoryInventory inventory, HttpServer server) {
  return KaratController(
    inventory: inventory,
    itemsApi: ItemApi(apiBase: 'http://127.0.0.1:${server.port}'),
    auth: FakeAuth(
      restored: const ShopUser(id: 'ada', email: 'ada@atelier.test'),
      token: 'token',
    ),
    now: () => DateTime(2026, 11, 21),
  );
}

class _Call {
  const _Call(this.method, this.body);

  final String method;
  final String body;
}

class _RecordingServer {
  _RecordingServer(this.server);

  final HttpServer server;
  final requests = <_Call>[];

  Future<void> close() => server.close();
}

Future<_RecordingServer> _recordingServer() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final recording = _RecordingServer(server);
  server.listen((request) async {
    final body = await utf8.decoder.bind(request).join();
    recording.requests.add(_Call(request.method, body));
    final created = request.method == 'POST';
    request.response
      ..statusCode = 200
      ..headers.contentType = ContentType.json
      ..write(
        jsonEncode(
          created ? _remoteJson('server-id') : <Map<String, Object?>>[],
        ),
      );
    await request.response.close();
  });
  return recording;
}

Future<HttpServer> _server({required int status, required Object body}) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((request) async {
    request.response
      ..statusCode = status
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(body));
    await request.response.close();
  });
  return server;
}

JewelleryItem _localPiece(String id) {
  return JewelleryItem(
    id: id,
    name: 'Local ring',
    kind: PieceKind.ring,
    metal: Metal.gold,
    purity: '18K',
    weightGrams: 3,
    costCents: 1000,
    notes: '',
    createdOn: const Day(2026, 11, 2),
  );
}

Map<String, Object?> _remoteJson(String id) {
  return {
    'id': id,
    'name': 'Server ring',
    'kind': 'ring',
    'metal': 'gold',
    'purity': '18K',
    'weightGrams': 3,
    'currencyId': somoniCurrencyId,
    'cost': 10,
    'soldOn': null,
    'soldAmount': null,
    'notes': '',
    'createdOn': '2026-11-02',
  };
}
