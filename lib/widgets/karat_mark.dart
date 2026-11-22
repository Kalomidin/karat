import 'package:material_ui/material_ui.dart';
import 'package:karat/theme/karat_theme.dart';

class KaratMark extends StatelessWidget {
  const KaratMark({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Karat',
      child: CustomPaint(
        size: Size.square(size),
        painter: const _MarkPainter(),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.34;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.045
      ..color = KaratColors.goldDeep;
    canvas.drawCircle(center, radius, ring);
    final inner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.012
      ..color = KaratColors.gold;
    canvas.drawCircle(center, radius * 0.62, inner);
    final stone = Paint()..color = KaratColors.gold;
    canvas.drawCircle(
      Offset(center.dx, center.dy - radius),
      size.width * 0.065,
      stone,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
