import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Base URL of karat-server. Set `KARAT_API` in `.env`.
String karatApiBase() {
  final fromFile = _env('KARAT_API');
  if (fromFile != null) return fromFile;
  if (Platform.isAndroid) return 'http://10.0.2.2:8080';
  return 'http://127.0.0.1:8080';
}

String? _env(String key) {
  if (!dotenv.isInitialized) return null;
  final value = dotenv.maybeGet(key)?.trim();
  if (value == null || value.isEmpty) return null;
  return value;
}
