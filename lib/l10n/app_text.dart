import 'package:flutter/foundation.dart';
import 'package:karat/auth/auth_client.dart';
import 'package:karat/domain/book_notice.dart';
import 'package:karat/domain/jewellery_item.dart';
import 'package:material_ui/material_ui.dart';

class AppText {
  const AppText(this.locale);

  final Locale locale;

  static const delegate = AppTextDelegate();

  static AppText of(BuildContext context) {
    final text = Localizations.of<AppText>(context, AppText);
    assert(text != null, 'AppText is missing from this context.');
    return text!;
  }

  bool get ru => locale.languageCode == 'ru';

  String get languageLabel => ru ? 'Язык' : 'Language';
  String get english => 'English';
  String get russian => 'Русский';
  String get currencyLabel => ru ? 'Валюта' : 'Currency';
  String get signInTitle => ru
      ? 'Книга учёта изделий на верстаке и в витрине.'
      : 'A stock book for the pieces on the bench and in the case.';
  String get continueWithGoogle =>
      ru ? 'Войти через Google' : 'Continue with Google';
  String get staysOnDevice => ru
      ? 'Изделия остаются на этом устройстве, в аккаунте Google, которым вы вошли.'
      : 'Pieces stay on this device, under the Google account that signs in.';
  String get signOutTitle => ru ? 'Выйти?' : 'Sign out?';
  String get signOutBody => ru
      ? 'Книга учёта останется на этом устройстве для этого аккаунта Google.'
      : 'The stock book stays on this device for this Google account.';
  String get stay => ru ? 'Остаться' : 'Stay';
  String get signOut => ru ? 'Выйти' : 'Sign out';
  String get account => ru ? 'Аккаунт' : 'Account';
  String get accountName => ru ? 'Имя' : 'Name';
  String get email => ru ? 'Почта' : 'Email';
  String get shopName => ru ? 'Название мастерской' : 'Shop name';
  String get save => ru ? 'Сохранить' : 'Save';
  String get ok => 'OK';
  String get updateFailed => ru ? 'Не удалось обновить' : 'Update failed';
  String get newPiece => ru ? 'Новое изделие' : 'New piece';
  String get editPiece => ru ? 'Изменить изделие' : 'Edit piece';
  String get stock => ru ? 'Наличие' : 'Stock';
  String get gains => ru ? 'Прибыль' : 'Gains';
  String get daySpan => ru ? 'День' : 'Day';
  String get weekSpan => ru ? 'Неделя' : 'Week';
  String get monthSpan => ru ? 'Месяц' : 'Month';
  String get customSpan => ru ? 'Свой' : 'Custom';
  String get todayLabel => ru ? 'Сегодня' : 'Today';
  String get thisMonth => ru ? 'Этот месяц' : 'This month';
  String get chooseDates => ru ? 'Выбрать даты' : 'Choose dates';
  String get inStock => ru ? 'В наличии' : 'In stock';
  String get sold => ru ? 'Продано' : 'Sold';
  String get searchPieces => ru ? 'Поиск изделий' : 'Search pieces';
  String get pieceType => ru ? 'Тип' : 'Type';
  String get anyType => ru ? 'Любой' : 'Any';
  String get filters => ru ? 'Фильтры' : 'Filters';
  String get clearFilters => ru ? 'Сбросить' : 'Clear';
  String get applyFilters => ru ? 'Показать' : 'Apply';
  String get nothingInStock =>
      ru ? 'В наличии пока ничего нет.' : 'Nothing in stock yet.';
  String get noSoldPieces =>
      ru ? 'Проданных изделий пока нет.' : 'No sold pieces yet.';
  String get noSearchMatches =>
      ru ? 'Ничего не найдено.' : 'No pieces match that search.';
  String get pieceSection => ru ? 'Изделие' : 'Piece';
  String get name => ru ? 'Название' : 'Name';
  String get purity => ru ? 'Проба' : 'Purity';
  String get money => ru ? 'Деньги' : 'Money';
  String currencyName(String code) {
    return switch (code) {
      'USD' => ru ? 'Доллар' : 'Dollar',
      'RUB' => ru ? 'Рубль' : 'Ruble',
      'TJS' => ru ? 'Сомони' : 'Somoni',
      _ => code,
    };
  }

  String get weight => ru ? 'Вес' : 'Weight';
  String get weightEach => ru ? 'Вес каждой' : 'Weight each';
  String get cost => ru ? 'Себестоимость' : 'Cost';
  String get costEach => ru ? 'Себестоимость каждой' : 'Cost each';
  String get quantity => ru ? 'Количество' : 'Quantity';
  String get notes => ru ? 'Заметки' : 'Notes';
  String get addPhoto => ru ? 'Добавить фото' : 'Add photo';
  String get changePhoto => ru ? 'Сменить фото' : 'Change photo';
  String get photoLibrary => ru ? 'Галерея' : 'Photo library';
  String get camera => ru ? 'Камера' : 'Camera';
  String get photoFailed => ru
      ? 'Фото не загрузилось. Проверьте соединение и попробуйте снова.'
      : 'The photo did not upload. Check the connection and try again.';
  String get savePiece => ru ? 'Сохранить' : 'Save piece';
  String savePieces(int count) =>
      ru ? 'Сохранить $count шт.' : 'Save $count pieces';
  String inStockCount(int count) => ru ? '$count в наличии' : '$count in stock';
  String get saving => ru ? 'Сохранение' : 'Saving';
  String get nameRequired =>
      ru ? 'Укажите название.' : 'Give the piece a name.';
  String get purityRequired => ru
      ? 'Укажите пробу, например 750 или 585.'
      : 'Add the purity, such as 750 or 585.';
  String get weightRequired =>
      ru ? 'Укажите вес в граммах.' : 'Enter the weight in grams.';
  String get costRequired =>
      ru ? 'Укажите себестоимость.' : 'Enter the cost of the piece.';
  String get grams => ru ? 'г' : 'g';
  String get markSold => ru ? 'Отметить продажу' : 'Mark sold';
  String get salePrice => ru ? 'Цена продажи' : 'Sale price';
  String soldOn(String date) => ru ? 'Дата продажи: $date' : 'Sold on $date';
  String soldLine(String date, String price) =>
      ru ? 'Продано $date · $price' : 'Sold $date · $price';
  String costLine(String price) => ru ? 'Себестоимость $price' : 'Cost $price';
  String costEachLine(String price) =>
      ru ? 'Себестоимость $price за шт.' : 'Cost $price each';
  String profitLine(String amount) => ru ? 'Прибыль $amount' : 'Profit $amount';
  String get profit => ru ? 'Прибыль' : 'Profit';
  String get spent => ru ? 'Потрачено' : 'Spent';
  String get earned => ru ? 'Получено' : 'Earned';
  String get recordSale => ru ? 'Записать продажу' : 'Record sale';
  String get thisWeek => ru ? 'Эта неделя' : 'This week';
  String get mondayToSunday => ru ? 'Понедельник–воскресенье' : 'Monday–Sunday';
  String get previousPeriod => ru ? 'Предыдущий период' : 'Previous period';
  String get nextPeriod => ru ? 'Следующий период' : 'Next period';
  String get noMovesInPeriod => ru
      ? 'В этом периоде ничего не поступало и не уходило.'
      : 'Nothing came in or left in this period.';
  String goldMovesEmpty(bool added) => added
      ? (ru
            ? 'В этом периоде золото не поступало.'
            : 'No gold came in during this period.')
      : (ru
            ? 'В этом периоде золото не уходило.'
            : 'No gold left during this period.');
  String get revenue => ru ? 'Выручка' : 'Revenue';
  String get pieces => ru ? 'Изделия' : 'Pieces';
  String get returnToStockTitle =>
      ru ? 'Вернуть в наличие?' : 'Return to stock?';
  String get returnToStockBody =>
      ru ? 'Эта продажа исчезнет из прибыли.' : 'This sale leaves the gains.';
  String get returnAction => ru ? 'Вернуть' : 'Return';
  String get returnToStock => ru ? 'Вернуть в наличие' : 'Return to stock';
  String get removeTitle => ru ? 'Удалить изделие?' : 'Remove this piece?';
  String get removeSoldBody => ru
      ? 'Оно исчезнет из книги и из прибыли, где было учтено.'
      : 'It leaves the stock book and the gains it was counted in.';
  String get removeStockBody =>
      ru ? 'Оно исчезнет из книги учёта.' : 'It leaves the stock book.';
  String get remove => ru ? 'Удалить' : 'Remove';
  String get keep => ru ? 'Оставить' : 'Keep';
  String get edit => ru ? 'Изменить' : 'Edit';
  String get pieceRemoved =>
      ru ? 'Это изделие удалено.' : 'This piece was removed.';
  String get registered => ru ? 'Поступило' : 'Registered';
  String get priceRequired =>
      ru ? 'Укажите цену продажи.' : 'Enter the price it sold for.';

  String kind(PieceKind kind) {
    if (!ru) return kind.label;
    return switch (kind) {
      PieceKind.ring => 'Кольцо',
      PieceKind.necklace => 'Колье',
      PieceKind.bracelet => 'Браслет',
      PieceKind.earrings => 'Серьги',
      PieceKind.pendant => 'Подвеска',
      PieceKind.brooch => 'Брошь',
      PieceKind.other => 'Другое',
    };
  }

  String notice(BookNotice notice) {
    return switch (notice) {
      BookNotice.signInAgain =>
        ru
            ? 'Войдите снова, прежде чем менять книгу.'
            : 'Sign in again before changing the book.',
      BookNotice.unreadable =>
        ru
            ? 'Не удалось прочитать книгу учёта на этом устройстве.'
            : 'The stock book on this device could not be read.',
      BookNotice.unreadableNoChange =>
        ru ? 'Книгу учёта не удалось прочитать, поэтому ничего не изменено.' : 'The stock book on this device could not be read, so nothing was changed.',
      BookNotice.unsaved =>
        ru
            ? 'Не удалось сохранить книгу учёта на этом устройстве.'
            : 'The stock book on this device could not be saved.',
      BookNotice.updateFailed => updateFailed,
      BookNotice.soldLocked =>
        ru
            ? 'Проданные изделия остаются как записаны.'
            : 'Sold pieces stay as they were recorded.',
      BookNotice.missing =>
        ru
            ? 'Этого изделия уже нет в книге.'
            : 'That piece is no longer in the book.',
      BookNotice.alreadySold =>
        ru ? 'Это изделие уже продано.' : 'This piece is already sold.',
      BookNotice.futureSale =>
        ru
            ? 'Нельзя датировать продажу будущим днём.'
            : "A sale can't be dated in the future.",
      BookNotice.stillInStock =>
        ru ? 'Это изделие ещё в наличии.' : 'This piece is still in stock.',
      BookNotice.priceRequired => priceRequired,
    };
  }

  String googleSetup({required bool android}) {
    if (android) {
      return ru
          ? 'Добавьте идентификатор веб-клиента в lib/config/google_auth.dart. Создайте Android-клиент OAuth для com.karat.karat и веб-клиент, затем вставьте идентификатор веб-клиента.'
          : 'Add the web client id in lib/config/google_auth.dart. Create an Android OAuth client for com.karat.karat and a Web client, then paste the Web client id.';
    }
    return ru
        ? 'Добавьте идентификатор iOS-клиента в lib/config/google_auth.dart и обратную схему URL в ios/Runner/Info.plist. Идентификатор пакета: com.karat.karat.'
        : 'Add the iOS client id in lib/config/google_auth.dart and the reversed client id URL scheme in ios/Runner/Info.plist. The bundle id is com.karat.karat.';
  }

  String authProblem(
    AuthProblem problem, {
    required bool android,
    String? detail,
  }) {
    return switch (problem) {
      AuthProblem.notConfigured => googleSetup(android: android),
      AuthProblem.userMismatch =>
        ru
            ? 'Этот аккаунт Google не совпадает с уже выбранным.'
            : 'That Google account does not match the one already signed in.',
      AuthProblem.interrupted =>
        ru ? 'Вход через Google прерван.' : 'Google sign-in was interrupted.',
      AuthProblem.failed =>
        detail ??
            (ru ? 'Не удалось войти через Google.' : 'Google sign-in failed.'),
    };
  }
}

class AppTextDelegate extends LocalizationsDelegate<AppText> {
  const AppTextDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'en' || locale.languageCode == 'ru';

  @override
  Future<AppText> load(Locale locale) {
    return SynchronousFuture(AppText(locale));
  }

  @override
  bool shouldReload(AppTextDelegate old) => false;
}

/// A saved choice wins. Otherwise Russian devices use Russian, and every
/// other device language uses English.
Locale resolveKaratLocale(Locale? device, Locale? chosen) {
  if (chosen != null) return Locale(chosen.languageCode);
  if (device?.languageCode == 'ru') return const Locale('ru');
  return const Locale('en');
}
