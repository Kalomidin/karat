import 'dart:io';
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

class PiecePhoto extends StatelessWidget {
  const PiecePhoto({
    super.key,
    required this.imageUrl,
    this.bytes,
    this.height,
    this.width,
    this.radius = 16,
  });

  final String imageUrl;
  final Uint8List? bytes;
  final double? height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final image = _image();
    if (image == null) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(height: height, width: width, child: image),
    );
  }

  Widget? _image() {
    if (bytes != null) {
      return Image.memory(bytes!, fit: BoxFit.cover);
    }
    if (imageUrl.isEmpty) return null;
    final uri = Uri.tryParse(imageUrl);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
      );
    }
    final file = File(imageUrl);
    if (!file.existsSync()) return null;
    return Image.file(file, fit: BoxFit.cover);
  }
}
