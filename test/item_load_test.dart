import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:karat/auth/auth_client.dart';
import 'package:karat/data/item_api.dart';
import 'package:karat/domain/book_notice.dart';
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
    expect(body['quantity'], 1);
  });

  test('creating several pieces stores each server row', () async {
    final inventory = MemoryInventory();
    final server = await _recordingServer();
    addTearDown(server.close);

    final controller = _controller(inventory, server.server);
    await controller.bootstrap();
    final saved = await controller.saveItem(
      _localPiece('phone-only'),
      quantity: 3,
    );

    expect(saved, isNull);
    expect(controller.items.map((item) => item.id).toSet(), {
      'server-0',
      'server-1',
      'server-2',
    });
    expect(inventory.books['ada'], hasLength(3));
    final post = server.requests.singleWhere((call) => call.method == 'POST');
    final body = jsonDecode(post.body) as Map<String, Object?>;
    expect(body['quantity'], 3);
    expect(body['weightGrams'], 3);
    expect(body['cost'], 10);
  });

  test('marking sold stores the sale on the server', () async {
    final inventory = MemoryInventory();
    inventory.books['ada'] = [_localPiece('ring')];
    final server = await _actionServer(
      sale: _remoteJson(
        'ring',
        soldOn: '2026-11-21',
        soldAmount: 15,
        name: 'Local ring',
      ),
    );
    addTearDown(server.close);

    final controller = _controller(inventory, server.server);
    await controller.bootstrap();
    final saved = await controller.markSold(
      'ring',
      soldCents: 1500,
      soldOn: const Day(2026, 11, 21),
    );

    expect(saved, isNull);
    expect(controller.items.single.isSold, isTrue);
    expect(controller.items.single.soldCents, 1500);
    final sale = server.requests.singleWhere(
      (call) => call.path.endsWith('/sale'),
    );
    final body = jsonDecode(sale.body) as Map<String, Object?>;
    expect(sale.method, 'POST');
    expect(body['soldOn'], const Day(2026, 11, 21).utcStart);
    expect(body['soldAmount'], 15);
  });

  test('a rejected sale leaves the piece in stock', () async {
    final inventory = MemoryInventory();
    inventory.books['ada'] = [_localPiece('ring')];
    final server = await _actionServer(saleStatus: 500);
    addTearDown(server.close);

    final controller = _controller(inventory, server.server);
    await controller.bootstrap();
    final saved = await controller.markSold(
      'ring',
      soldCents: 1500,
      soldOn: const Day(2026, 11, 21),
    );

    expect(saved, BookNotice.updateFailed);
    expect(controller.items.single.isSold, isFalse);
  });

  test('returning a piece clears the sale on the server', () async {
    final inventory = MemoryInventory();
    inventory.books['ada'] = [_soldPiece('ring')];
    final server = await _actionServer(returned: _remoteJson('ring'));
    addTearDown(server.close);

    final controller = _controller(inventory, server.server);
    await controller.bootstrap();
    final saved = await controller.returnToStock('ring');

    expect(saved, isNull);
    expect(controller.items.single.isSold, isFalse);
    expect(
      server.requests
          .singleWhere((call) => call.path.endsWith('/return'))
          .method,
      'POST',
    );
  });

  test('editing a quantity deletes extras and adds pieces', () async {
    final inventory = MemoryInventory()
      ..books['ada'] = [_localPiece('a'), _localPiece('b'), _localPiece('c')];
    final server = await _editServer();
    addTearDown(server.close);

    final controller = _controller(inventory, server.server);
    await controller.bootstrap();
    final shrunk = await controller.saveItem(
      controller.find('a')!,
      quantity: 1,
    );

    expect(shrunk, isNull);
    expect(controller.items.map((item) => item.id), ['a']);
    expect(
      server.requests
          .where((call) => call.method == 'DELETE')
          .map((call) => call.path)
          .toList(),
      ['/item/b', '/item/c'],
    );

    final grown = await controller.saveItem(controller.find('a')!, quantity: 3);

    expect(grown, isNull);
    expect(controller.items.map((item) => item.id).toSet(), {
      'a',
      'extra-0',
      'extra-1',
    });
    final post = server.requests.lastWhere((call) => call.method == 'POST');
    expect((jsonDecode(post.body) as Map)['quantity'], 2);
  });

  test('deleting a piece removes it on the server', () async {
    final inventory = MemoryInventory();
    inventory.books['ada'] = [_localPiece('ring')];
    final server = await _actionServer();
    addTearDown(server.close);

    final controller = _controller(inventory, server.server);
    await controller.bootstrap();
    final saved = await controller.deleteItem('ring');

    expect(saved, isNull);
    expect(controller.items, isEmpty);
    expect(
      server.requests.singleWhere((call) => call.method == 'DELETE').path,
      '/item/ring',
    );
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
  const _Call(this.method, this.path, this.body);

  final String method;
  final String path;
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
    recording.requests.add(_Call(request.method, request.uri.path, body));
    final created = request.method == 'POST';
    var count = 1;
    if (created && body.isNotEmpty) {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['quantity'] is int) {
        count = decoded['quantity'] as int;
      }
    }
    final createdRows = [
      for (var i = 0; i < count; i++)
        _remoteJson(count == 1 ? 'server-id' : 'server-$i', name: 'Local ring'),
    ];
    request.response
      ..statusCode = 200
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(created ? createdRows : <Map<String, Object?>>[]));
    await request.response.close();
  });
  return recording;
}

Future<_RecordingServer> _editServer() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final recording = _RecordingServer(server);
  server.listen((request) async {
    final body = await utf8.decoder.bind(request).join();
    recording.requests.add(_Call(request.method, request.uri.path, body));
    final response = request.response;
    response.headers.contentType = ContentType.json;
    if (request.method == 'GET') {
      response.statusCode = 500;
      response.write(jsonEncode({'error': 'down'}));
    } else if (request.method == 'PUT') {
      response.statusCode = 200;
      final id = request.uri.pathSegments.last;
      response.write(jsonEncode(_remoteJson(id, name: 'Local ring')));
    } else if (request.method == 'DELETE') {
      response.statusCode = 200;
      response.write(jsonEncode({'ok': true}));
    } else if (request.method == 'POST') {
      final decoded = jsonDecode(body);
      final count = decoded is Map && decoded['quantity'] is int
          ? decoded['quantity'] as int
          : 1;
      response.statusCode = 200;
      response.write(
        jsonEncode([
          for (var i = 0; i < count; i++)
            _remoteJson('extra-$i', name: 'Local ring'),
        ]),
      );
    } else {
      response.statusCode = 404;
    }
    await response.close();
  });
  return recording;
}

Future<_RecordingServer> _actionServer({
  Object? sale,
  int saleStatus = 200,
  Object? returned,
}) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final recording = _RecordingServer(server);
  server.listen((request) async {
    final body = await utf8.decoder.bind(request).join();
    recording.requests.add(_Call(request.method, request.uri.path, body));
    final path = request.uri.path;
    final response = request.response;
    response.headers.contentType = ContentType.json;
    if (request.method == 'GET') {
      response.statusCode = 500;
      response.write(jsonEncode({'error': 'down'}));
    } else if (path.endsWith('/sale')) {
      response.statusCode = saleStatus;
      response.write(jsonEncode(sale ?? {'error': 'sale'}));
    } else if (path.endsWith('/return')) {
      response.statusCode = 200;
      response.write(jsonEncode(returned));
    } else if (request.method == 'DELETE') {
      response.statusCode = 200;
      response.write(jsonEncode({'ok': true}));
    } else {
      response.statusCode = 404;
    }
    await response.close();
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

JewelleryItem _soldPiece(String id) {
  return _localPiece(id).markSold(on: const Day(2026, 11, 20), cents: 1500);
}

Map<String, Object?> _remoteJson(
  String id, {
  String name = 'Server ring',
  String? soldOn,
  int? soldAmount,
}) {
  return {
    'id': id,
    'name': name,
    'kind': 'ring',
    'metal': 'gold',
    'purity': '18K',
    'weightGrams': 3,
    'currencyId': somoniCurrencyId,
    'cost': 10,
    'soldOn': soldOn,
    'soldAmount': soldAmount,
    'notes': '',
    'createdOn': '2026-11-02',
  };
}
