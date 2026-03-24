abstract class StorageImplementation {
  Future<String> saveImageToGallery(String sourcePath);
  Future<bool> fileExists(String path);
}

StorageImplementation getImplementation() => throw UnimplementedError();
