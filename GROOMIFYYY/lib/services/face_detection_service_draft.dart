import 'package:camera/camera.dart';
import '../models/face_shape.dart';

import 'package:groomify/services/face_detection/face_detection_stub.dart'
    if (dart.library.io) 'face_detection/face_detection_mobile.dart'
    if (dart.library.js_interop) 'face_detection/face_detection_web.dart';

class FaceDetectionService {
  static final FaceDetectionService instance = FaceDetectionService._init();

  late final FaceDetectionImplementation _implementation;

  FaceDetectionService._init() {
    // This will instantiate the correct class based on the import above
    // Since we can't easily do `new Implementation()` with conditional imports directly in the same way 
    // without a factory, we usually use a top level function or check for class availability.
    // However, the cleanest way in modern Dart is to use the conditional import to define a type alias 
    // or just have the same class name in both files. 
    
    // Approach: The files `mobile.dart` and `web.dart` should both export a class named 
    // `FaceDetectionImplementationMobile` or `Web` mapping to a common interface? 
    // A simpler way: The conditional import defines which file `getImplementation` comes from.
    
   _implementation = _createImplementation();
  }
  
  Future<FaceShapeResult?> detectFaceShape(XFile imageFile) {
    return _implementation.detectFaceShape(imageFile);
  }

  void dispose() {
    _implementation.dispose();
  }
}

// These functions should be in the respective files instead of the class directly to avoid type errors
// But since I defined specific classes in the previous files, I need to adjust them slightly.
// To make it simple: 
// I will just instantiate the class based on conditional import.

FaceDetectionImplementation _createImplementation() {
  // This function body is actually tricky without modifying the other files to share a factory function.
  // Let's use the standard "Stub/Mobile/Web" factory pattern.
  // Actually, I'll update the mobile/web files to expose a `getHelper` function.
  throw UnimplementedError('This should be replaced by conditional imports'); 
}
