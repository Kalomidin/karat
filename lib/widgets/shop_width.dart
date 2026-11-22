import 'package:material_ui/material_ui.dart';

/// Keeps the book a readable width on a tablet without stretching a phone.
class ShopWidth extends StatelessWidget {
  const ShopWidth({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth > 640 ? 640.0 : constraints.maxWidth;
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: width,
            height: constraints.maxHeight,
            child: child,
          ),
        );
      },
    );
  }
}
