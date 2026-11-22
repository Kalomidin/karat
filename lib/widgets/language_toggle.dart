import 'package:karat/l10n/app_text.dart';
import 'package:karat/l10n/locale_controller.dart';
import 'package:karat/theme/karat_theme.dart';
import 'package:material_ui/material_ui.dart';

class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key, required this.locales});

  final LocaleController locales;

  @override
  Widget build(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    final text = AppText.of(context);
    return Semantics(
      label: text.languageLabel,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LangButton(
            key: const Key('lang-en'),
            label: 'EN',
            selected: code != 'ru',
            onTap: () => locales.choose('en'),
          ),
          _LangButton(
            key: const Key('lang-ru'),
            label: 'RU',
            selected: code == 'ru',
            onTap: () => locales.choose('ru'),
          ),
        ],
      ),
    );
  }
}

class _LangButton extends StatelessWidget {
  const _LangButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: selected ? null : onTap,
      style: TextButton.styleFrom(
        foregroundColor: selected ? KaratColors.ink : KaratColors.goldDeep,
        disabledForegroundColor: KaratColors.ink,
        minimumSize: const Size(40, 36),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        textStyle: TextStyle(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          letterSpacing: 0.4,
        ),
      ),
      child: Text(label),
    );
  }
}
