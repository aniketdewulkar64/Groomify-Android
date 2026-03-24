import 'package:groomify/services/storage/storage_stub.dart';

export 'package:groomify/services/storage/storage_stub.dart';

class StorageImplementationWeb implements StorageImplementation {
  @override
  Future<String> saveImageToGallery(String sourcePath) async {
    // On web we cannot save to persistent gallery easily. 
    // Just return the source path (blob url) or empty.
    return sourcePath;
  }

  @override
  Future<bool> fileExists(String path) async {
    return true; // Assume exists for network/blob
  }
}

StorageImplementation getImplementation() => StorageImplementationWeb();
