import 'package:karat/l10n/app_text.dart';
import 'package:karat/l10n/locale_controller.dart';
import 'package:karat/screens/stock_screen.dart';
import 'package:karat/screens/week_screen.dart';
import 'package:karat/screens/item_form_screen.dart';
import 'package:karat/state/karat_controller.dart';
import 'package:karat/theme/karat_theme.dart';
import 'package:karat/widgets/language_toggle.dart';
import 'package:karat/widgets/shop_width.dart';
import 'package:material_ui/material_ui.dart';

class ShopShell extends StatefulWidget {
  const ShopShell({super.key, required this.controller, required this.locales});

  final KaratController controller;
  final LocaleController locales;

  @override
  State<ShopShell> createState() => _ShopShellState();
}

class _ShopShellState extends State<ShopShell> {
  int _index = 0;

  Future<void> _confirmSignOut() async {
    final text = AppText.of(context);
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(text.signOutTitle),
          content: Text(text.signOutBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(text.stay),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(text.signOut),
            ),
          ],
        );
      },
    );
    if (leave == true && mounted) {
      await widget.controller.signOut();
    }
  }

  void _openForm() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ItemFormScreen(controller: widget.controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final user = controller.user;
        final text = AppText.of(context);
        final storage = controller.storageNotice;
        return Scaffold(
          floatingActionButton: _index == 0
              ? FloatingActionButton.extended(
                  onPressed: _openForm,
                  backgroundColor: KaratColors.ink,
                  foregroundColor: KaratColors.cream,
                  icon: const Icon(Icons.add),
                  label: Text(text.newPiece),
                )
              : null,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (index) => setState(() => _index = index),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.menu_book_outlined),
                selectedIcon: const Icon(Icons.menu_book),
                label: text.stock,
              ),
              NavigationDestination(
                icon: const Icon(Icons.calendar_view_week_outlined),
                selectedIcon: const Icon(Icons.calendar_view_week),
                label: text.week,
              ),
            ],
          ),
          body: SafeArea(
            bottom: false,
            child: ShopWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Karat',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium,
                              ),
                              if (user != null)
                                Text(
                                  user.email,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: KaratColors.ink.withValues(
                                          alpha: 0.68,
                                        ),
                                      ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: text.signOut,
                          onPressed: _confirmSignOut,
                          icon: const Icon(Icons.logout),
                        ),
                        LanguageToggle(locales: widget.locales),
                      ],
                    ),
                  ),
                  if (storage != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                      child: Text(
                        text.notice(storage),
                        style: const TextStyle(color: KaratColors.loss),
                      ),
                    ),
                  Expanded(
                    child: IndexedStack(
                      index: _index,
                      children: [
                        StockScreen(controller: controller),
                        WeekScreen(controller: controller),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
