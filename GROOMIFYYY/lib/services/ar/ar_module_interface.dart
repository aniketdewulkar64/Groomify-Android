import 'dart:ui';
import 'package:google_mlkit_face_mesh_detection/google_mlkit_face_mesh_detection.dart';

abstract class ARModule {
  void paint(Canvas canvas, FaceMesh face, Size size);
}
