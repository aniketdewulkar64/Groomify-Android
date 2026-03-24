import 'dart:ui';
import 'package:google_mlkit_face_mesh_detection/google_mlkit_face_mesh_detection.dart';
import 'package:groomify/services/ar/ar_module_interface.dart';

class HairstyleModule implements ARModule {
  @override
  void paint(Canvas canvas, FaceMesh face, Size size) {
    // Hairstyle implementation
    // Will position hair assets above the forehead
  }
}
