import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

class KaratMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const KaratMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    if (locale.languageCode == 'ru') {
      return SynchronousFuture(const RussianMaterialLocalizations());
    }
    return SynchronousFuture(const DefaultMaterialLocalizations());
  }

  @override
  bool shouldReload(KaratMaterialLocalizationsDelegate old) => false;
}

class RussianMaterialLocalizations extends DefaultMaterialLocalizations {
  const RussianMaterialLocalizations();

  String _format(DateTime date, String pattern) {
    return DateFormat(pattern, 'ru').format(date);
  }

  @override
  String formatFullDate(DateTime date) => _format(date, 'EEEE, d MMMM y');

  @override
  String formatMediumDate(DateTime date) => _format(date, 'EEE, d MMM');

  @override
  String formatShortDate(DateTime date) => _format(date, 'd MMM y');

  @override
  String formatMonthYear(DateTime date) => _format(date, 'LLLL y');

  @override
  String formatShortMonthDay(DateTime date) => _format(date, 'd MMM');

  @override
  String formatCompactDate(DateTime date) => _format(date, 'dd.MM.y');

  @override
  List<String> get narrowWeekdays => const [
    'вс',
    'пн',
    'вт',
    'ср',
    'чт',
    'пт',
    'сб',
  ];

  @override
  int get firstDayOfWeekIndex => 1;

  @override
  String get cancelButtonLabel => 'Отмена';

  @override
  String get okButtonLabel => 'ОК';

  @override
  String get saveButtonLabel => 'Сохранить';

  @override
  String get datePickerHelpText => 'Выберите дату';

  @override
  String get nextMonthTooltip => 'Следующий месяц';

  @override
  String get previousMonthTooltip => 'Предыдущий месяц';
}

class KaratCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const KaratCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'en' || locale.languageCode == 'ru';

  @override
  Future<CupertinoLocalizations> load(Locale locale) {
    if (locale.languageCode == 'ru') {
      return SynchronousFuture(const RussianCupertinoLocalizations());
    }
    return SynchronousFuture(const DefaultCupertinoLocalizations());
  }

  @override
  bool shouldReload(KaratCupertinoLocalizationsDelegate old) => false;
}

class RussianCupertinoLocalizations extends DefaultCupertinoLocalizations {
  const RussianCupertinoLocalizations();

  static const _weekdays = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];
  static const _shortMonths = [
    'янв.',
    'февр.',
    'мар.',
    'апр.',
    'мая',
    'июня',
    'июля',
    'авг.',
    'сент.',
    'окт.',
    'нояб.',
    'дек.',
  ];
  static const _months = [
    'январь',
    'февраль',
    'март',
    'апрель',
    'май',
    'июнь',
    'июль',
    'август',
    'сентябрь',
    'октябрь',
    'ноябрь',
    'декабрь',
  ];

  @override
  String datePickerMonth(int monthIndex) => _months[monthIndex - 1];

  @override
  String datePickerStandaloneMonth(int monthIndex) => _months[monthIndex - 1];

  @override
  String datePickerDayOfMonth(int dayIndex, [int? weekDay]) {
    if (weekDay == null) return dayIndex.toString();
    return ' ${_weekdays[weekDay - DateTime.monday]} $dayIndex ';
  }

  @override
  String datePickerMediumDate(DateTime date) {
    return '${_weekdays[date.weekday - DateTime.monday]} '
        '${_shortMonths[date.month - DateTime.january]} '
        '${date.day.toString().padRight(2)}';
  }

  @override
  DatePickerDateOrder get datePickerDateOrder => DatePickerDateOrder.dmy;

  @override
  String get todayLabel => 'Сегодня';

  @override
  String get alertDialogLabel => 'Предупреждение';

  @override
  String get cutButtonLabel => 'Вырезать';

  @override
  String get copyButtonLabel => 'Скопировать';

  @override
  String get pasteButtonLabel => 'Вставить';

  @override
  String get clearButtonLabel => 'Очистить';

  @override
  String get selectAllButtonLabel => 'Выбрать всё';

  @override
  String get lookUpButtonLabel => 'Найти';

  @override
  String get searchWebButtonLabel => 'Искать в интернете';

  @override
  String get shareButtonLabel => 'Поделиться…';

  @override
  String get searchTextFieldPlaceholderLabel => 'Поиск';

  @override
  String get cancelButtonLabel => 'Отмена';

  @override
  String get backButtonLabel => 'Назад';

  @override
  String get modalBarrierDismissLabel => 'Закрыть';

  @override
  String get menuDismissLabel => 'Закрыть меню';
}
