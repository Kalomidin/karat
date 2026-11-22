import 'package:karat/l10n/app_text.dart';
import 'package:karat/l10n/locale_controller.dart';
import 'package:karat/theme/karat_theme.dart';
import 'package:material_ui/material_ui.dart';

class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key, required this.locales});

  final LocaleController locales;

  @override
  Widget build(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode == 'ru'
        ? 'ru'
        : 'en';
    final text = AppText.of(context);
    return PopupMenuButton<String>(
      key: const Key('open-language'),
      tooltip: text.languageLabel,
      initialValue: code,
      onSelected: locales.choose,
      itemBuilder: (context) {
        return [
          PopupMenuItem(
            key: const Key('lang-en'),
            value: 'en',
            child: Text(text.english),
          ),
          PopupMenuItem(
            key: const Key('lang-ru'),
            value: 'ru',
            child: Text(text.russian),
          ),
        ];
      },
      child: _CurrentChoice(code == 'ru' ? 'RU' : 'EN'),
    );
  }
}

class _CurrentChoice extends StatelessWidget {
  const _CurrentChoice(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        label,
        style: const TextStyle(
          color: KaratColors.ink,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
