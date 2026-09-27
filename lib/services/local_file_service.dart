import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class LocalFileService {
  static final LocalFileService instance = LocalFileService._internal();

  LocalFileService._internal();

  /// Diskdan rasm (PNG/JPG) tanlash va lokal 'library_assets' papkasiga nusxalash
  Future<String?> pickAndSaveImage({required String category}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      );

      if (result == null || result.files.isEmpty || result.files.single.path == null) {
        return null;
      }

      final sourcePath = result.files.single.path!;
      final sourceFile = File(sourcePath);

      final appDocDir = await getApplicationDocumentsDirectory();
      final assetsDir = Directory(p.join(appDocDir.path, 'library_assets', category));

      if (!await assetsDir.exists()) {
        await assetsDir.create(recursive: true);
      }

      final extension = p.extension(sourcePath);
      final newFileName = '${category}_${DateTime.now().millisecondsSinceEpoch}$extension';
      final destinationPath = p.join(assetsDir.path, newFileName);

      await sourceFile.copy(destinationPath);
      return destinationPath;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [LOCAL FILE SERVICE ERROR]: $e');
      }
      return null;
    }
  }
}
