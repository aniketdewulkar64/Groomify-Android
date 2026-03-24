import 'package:groomify/services/storage/storage_stub.dart'
    if (dart.library.io) 'storage_mobile.dart'
    if (dart.library.js_interop) 'storage_web.dart' as impl;

class StorageService {
  static final StorageService instance = StorageService._init();
  late final impl.StorageImplementation _implementation;

  StorageService._init() {
    _implementation = impl.getImplementation();
  }

  Future<String> saveImageToGallery(String sourcePath) => _implementation.saveImageToGallery(sourcePath);
  Future<bool> fileExists(String path) => _implementation.fileExists(path);
}
