import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:karat/app.dart';
import 'package:karat/auth/google_auth_client.dart';
import 'package:karat/data/inventory_repository.dart';
import 'package:karat/state/karat_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('en_US');
  await initializeDateFormatting('ru');
  runApp(
    KaratApp(
      controller: KaratController(
        inventory: SharedPreferencesInventory(),
        auth: GoogleAuthClient(),
      ),
    ),
  );
}
