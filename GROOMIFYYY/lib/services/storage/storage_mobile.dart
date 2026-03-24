import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';
import 'package:groomify/services/storage/storage_stub.dart';

export 'package:groomify/services/storage/storage_stub.dart';

class StorageImplementationMobile implements StorageImplementation {
  @override
  Future<String> saveImageToGallery(String sourcePath) async {
      final appDir = await getApplicationDocumentsDirectory();
      final galleryDir = Directory(
        path.join(
          appDir.path,
          'GroomifyGallery',
          'FaceShapeResults',
          DateFormat('yyyy-MM-dd').format(DateTime.now()),
        ),
      );

      if (!await galleryDir.exists()) {
        await galleryDir.create(recursive: true);
      }

      final imageFile = File(sourcePath);
      final fileName = path.basename(sourcePath);
      final savedImagePath = path.join(galleryDir.path, fileName);
      await imageFile.copy(savedImagePath);
      return savedImagePath;
  }

  @override
  Future<bool> fileExists(String path) async {
    return File(path).exists();
  }
}

StorageImplementation getImplementation() => StorageImplementationMobile();
