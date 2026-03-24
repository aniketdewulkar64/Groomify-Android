import 'package:flutter/material.dart';
import 'package:google_mlkit_face_mesh_detection/google_mlkit_face_mesh_detection.dart';
import 'package:groomify/services/ar/ar_module_interface.dart';

class ARPainter extends CustomPainter {
  final List<FaceMesh> faces;
  final List<ARModule> activeModules;
  final Size absoluteImageSize;
  final InputImageRotation rotation;

  ARPainter({
    required this.faces,
    required this.activeModules,
    required this.absoluteImageSize,
    required this.rotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final face in faces) {
      // Transform logic would go here to match camera image size to screen size
      // simplified for now implies direct mapping or handled by modules
      
      for (final module in activeModules) {
        module.paint(canvas, face, size);
      }
    }
  }

  @override
  bool shouldRepaint(ARPainter oldDelegate) {
    return oldDelegate.faces != faces || oldDelegate.activeModules != activeModules;
  }
}
