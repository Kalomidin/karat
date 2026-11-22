import 'package:karat/l10n/app_text.dart';
import 'package:material_ui/material_ui.dart';

Future<void> showUpdateFailed(BuildContext context) {
  final text = AppText.of(context);
  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(text.updateFailed),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(text.ok),
          ),
        ],
      );
    },
  );
}
