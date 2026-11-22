import 'dart:io';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:karat/data/piece_photo_file.dart';
import 'package:karat/data/piece_photo_upload.dart';
import 'package:karat/l10n/app_text.dart';
import 'package:karat/state/karat_controller.dart';
import 'package:karat/theme/karat_theme.dart';
import 'package:karat/widgets/shop_width.dart';
import 'package:material_ui/material_ui.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key, required this.controller});

  final KaratController controller;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _shop;
  Uint8List? _pendingBytes;
  var _pendingType = 'image/jpeg';
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final user = widget.controller.user;
    _name = TextEditingController(text: user?.name ?? '');
    _email = TextEditingController(text: user?.email ?? '');
    _shop = TextEditingController(text: user?.shopName ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _shop.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final text = AppText.of(context);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                key: const Key('photo-library'),
                title: Text(text.photoLibrary),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                key: const Key('photo-camera'),
                title: Text(text.camera),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );
    if (source == null) return;
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 80,
      );
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _pendingBytes = bytes;
        _pendingType = contentTypeForPhoto(file.name, file.mimeType);
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppText.of(context).photoFailed)));
    }
  }

  Future<void> _save() async {
    final user = widget.controller.user;
    if (user == null || _saving) return;
    setState(() => _saving = true);
    String? photoUrl;
    final pending = _pendingBytes;
    if (pending != null) {
      try {
        photoUrl = await saveProfilePhoto(
          user.id,
          pending,
          extensionForPhoto(_pendingType),
        );
      } catch (_) {
        if (!mounted) return;
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppText.of(context).photoFailed)),
        );
        return;
      }
    }
    await widget.controller.updateAccount(
      name: _name.text,
      shopName: _shop.text,
      photoUrl: photoUrl,
    );
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final user = widget.controller.user;
    final photo = user?.photoUrl?.trim() ?? '';
    return Scaffold(
      appBar: AppBar(title: Text(text.account)),
      body: ShopWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Center(
              child: GestureDetector(
                key: const Key('account-photo'),
                onTap: _saving ? null : _pickPhoto,
                child: CircleAvatar(
                  radius: 42,
                  backgroundColor: KaratColors.cream,
                  backgroundImage: _portrait(photo),
                  child: _portrait(photo) == null
                      ? Text(
                          _initial(user?.label ?? ''),
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(color: KaratColors.goldDeep),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: _saving ? null : _pickPhoto,
                child: Text(
                  _pendingBytes == null && photo.isEmpty
                      ? text.addPhoto
                      : text.changePhoto,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('account-name'),
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: text.accountName),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('account-email'),
              readOnly: true,
              controller: _email,
              decoration: InputDecoration(labelText: text.email),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('account-shop'),
              controller: _shop,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: text.shopName),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton(
            key: const Key('save-account'),
            onPressed: _saving ? null : _save,
            child: Text(_saving ? text.saving : text.save),
          ),
        ),
      ),
    );
  }

  ImageProvider? _portrait(String photo) {
    final pending = _pendingBytes;
    if (pending != null) return MemoryImage(pending);
    if (photo.isEmpty) return null;
    final uri = Uri.tryParse(photo);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return NetworkImage(photo);
    }
    final file = File(photo);
    if (!file.existsSync()) return null;
    return FileImage(file);
  }
}

String _initial(String label) {
  final trimmed = label.trim();
  if (trimmed.isEmpty) return '';
  return trimmed.characters.first.toUpperCase();
}
