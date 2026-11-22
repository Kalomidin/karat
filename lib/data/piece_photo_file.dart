import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

Future<String> savePiecePhoto(
  String id,
  Uint8List bytes,
  String extension,
) async {
  final root = await getApplicationDocumentsDirectory();
  final folder = Directory('${root.path}/piece-photos');
  await folder.create(recursive: true);
  final file = File('${folder.path}/$id$extension');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

Future<String> saveProfilePhoto(
  String userId,
  Uint8List bytes,
  String extension,
) async {
  final root = await getApplicationDocumentsDirectory();
  final folder = Directory('${root.path}/profile-photos');
  await folder.create(recursive: true);
  final file = File('${folder.path}/$userId$extension');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
