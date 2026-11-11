import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../core/fa.dart';
import '../core/theme.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import 'widgets.dart';

/// عکس‌های پیشرفت: فقط داخل حافظه خصوصی برنامه ذخیره می‌شوند (در گالری گوشی دیده نمی‌شوند).
class PhotosScreen extends StatelessWidget {
  const PhotosScreen({super.key});

  Future<void> _add(BuildContext context, ImageSource src) async {
    final s = context.read<AppState>();
    try {
      final x = await ImagePicker().pickImage(source: src, maxWidth: 1600, imageQuality: 85);
      if (x == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final folder = Directory('${dir.path}/progress_photos');
      if (!await folder.exists()) await folder.create(recursive: true);
      final name = 'p_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final saved = await File(x.path).copy('${folder.path}/$name');
      await s.addPhoto(saved.path);
      if (context.mounted) toast(context, 'عکس ذخیره شد.');
    } catch (_) {
      if (context.mounted) toast(context, 'افزودن عکس ممکن نشد.');
    }
  }

  void _chooser(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: C.bg(context),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('گرفتن عکس با دوربین'),
              onTap: () {
                Navigator.pop(c);
                _add(context, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('انتخاب از گالری'),
              onTap: () {
                Navigator.pop(c);
                _add(context, ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _view(BuildContext context, PhotoEntry p) {
    final s = context.read<AppState>();
    showDialog(
      context: context,
      builder: (c) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: InteractiveViewer(
                child: Image.file(File(p.path),
                    errorBuilder: (_, __, ___) => const Padding(
                          padding: EdgeInsets.all(40),
                          child: Text('فایل عکس پیدا نشد.',
                              style: TextStyle(color: Colors.white)),
                        )),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Text(jalaliFull(parseKey(p.date)),
                      style: const TextStyle(color: Colors.white)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () async {
                      final ok = await confirmDialog(
                          context, 'حذف عکس', 'این عکس برای همیشه حذف شود؟',
                          ok: 'حذف', danger: true);
                      if (!ok) return;
                      try {
                        final f = File(p.path);
                        if (await f.exists()) await f.delete();
                      } catch (_) {}
                      await s.deletePhoto(p);
                      if (c.mounted) Navigator.pop(c);
                    },
                    icon: const Icon(Icons.delete_outline_rounded, color: C.red),
                    label: const Text('حذف', style: TextStyle(color: C.red)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(c),
                    child: const Text('بستن'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final list = s.photos; // جدیدترین اول
    return Scaffold(
      appBar: AppBar(
        title: const Text('عکس‌های پیشرفت'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: C.green,
        foregroundColor: Colors.white,
        onPressed: () => _chooser(context),
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('افزودن عکس'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        children: [
          AppCard(
            color: C.card2(context),
            child: Row(
              children: [
                const Icon(Icons.lock_outline_rounded, color: C.green),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'عکس‌ها فقط داخل حافظه خصوصی فیت‌لایف ذخیره می‌شوند، در گالری دیده نمی‌شوند و به جایی ارسال نمی‌شوند.',
                    style: TextStyle(fontSize: 12.5, color: C.muted(context), height: 1.8),
                  ),
                ),
              ],
            ),
          ),
          if (list.length >= 2) ...[
            const SectionTitle('مقایسه اول و آخر'),
            Row(
              children: [
                Expanded(child: _thumb(context, list.last, 'شروع', 0.78)),
                const SizedBox(width: 10),
                Expanded(child: _thumb(context, list.first, 'آخرین', 0.78)),
              ],
            ),
          ],
          const SectionTitle('همه عکس‌ها'),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Text('هنوز عکسی اضافه نشده.',
                    style: TextStyle(color: C.muted(context))),
              ),
            ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.78,
            ),
            itemCount: list.length,
            itemBuilder: (c, i) => _thumb(context, list[i], null, 0.78),
          ),
        ],
      ),
    );
  }

  Widget _thumb(BuildContext context, PhotoEntry p, String? label, double ratio) {
    return GestureDetector(
      onTap: () => _view(context, p),
      child: AspectRatio(
        aspectRatio: ratio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(
                File(p.path),
                fit: BoxFit.cover,
                cacheWidth: 500,
                errorBuilder: (_, __, ___) => Container(
                  color: C.card2(context),
                  child: const Icon(Icons.broken_image_outlined),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  color: Colors.black54,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    label == null
                        ? jalaliShort(parseKey(p.date))
                        : '$label • ${jalaliShort(parseKey(p.date))}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
