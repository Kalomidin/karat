import 'dart:io';

import 'package:karat/l10n/app_text.dart';
import 'package:karat/l10n/locale_controller.dart';
import 'package:karat/state/karat_controller.dart';
import 'package:karat/theme/karat_theme.dart';
import 'package:karat/widgets/karat_mark.dart';
import 'package:karat/widgets/language_toggle.dart';
import 'package:karat/widgets/shop_width.dart';
import 'package:material_ui/material_ui.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({
    super.key,
    required this.controller,
    required this.locales,
  });

  final KaratController controller;
  final LocaleController locales;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    return Scaffold(
      body: SafeArea(
        child: ShopWidth(
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              final problem = controller.authProblem;
              final notice = problem == null
                  ? (controller.needsGoogleSetup
                        ? text.googleSetup(android: Platform.isAndroid)
                        : null)
                  : text.authProblem(
                      problem,
                      android: Platform.isAndroid,
                      detail: controller.authDetail,
                    );
              final blocked = controller.needsGoogleSetup;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: LanguageToggle(locales: locales),
                    ),
                    const Spacer(),
                    const KaratMark(size: 76),
                    const SizedBox(height: 28),
                    Text(
                      'Karat',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      text.signInTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        height: 1.35,
                        color: KaratColors.ink.withValues(alpha: 0.78),
                      ),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: blocked || controller.signingIn
                          ? null
                          : controller.signIn,
                      child: controller.signingIn
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(text.continueWithGoogle),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      text.staysOnDevice,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: KaratColors.ink.withValues(alpha: 0.68),
                        height: 1.4,
                      ),
                    ),
                    if (notice != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        notice,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: KaratColors.loss, height: 1.4),
                      ),
                    ],
                    const SizedBox(height: 28),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
