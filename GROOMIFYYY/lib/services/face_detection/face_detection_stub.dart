import 'package:camera/camera.dart';
import '../../models/face_shape.dart';

abstract class FaceDetectionImplementation {
  Future<FaceShapeResult?> detectFaceShape(XFile imageFile);
  void dispose();
}

FaceDetectionImplementation getImplementation() => throw UnimplementedError();
