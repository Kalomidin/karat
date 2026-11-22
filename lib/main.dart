import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:karat/app.dart';
import 'package:karat/auth/google_auth_client.dart';
import 'package:karat/data/currency_api.dart';
import 'package:karat/data/currency_store.dart';
import 'package:karat/data/inventory_repository.dart';
import 'package:karat/data/item_api.dart';
import 'package:karat/data/profile_store.dart';
import 'package:karat/state/karat_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env', isOptional: true);
  await initializeDateFormatting('en_US');
  await initializeDateFormatting('ru');
  runApp(
    KaratApp(
      controller: KaratController(
        inventory: SharedPreferencesInventory(),
        profiles: PreferencesProfileStore(),
        itemsApi: ItemApi(),
        currenciesApi: CurrencyApi(),
        currencyStore: PreferencesCurrencyStore(),
        auth: GoogleAuthClient(),
      ),
    ),
  );
}
