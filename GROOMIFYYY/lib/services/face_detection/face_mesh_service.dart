import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_mesh_detection/google_mlkit_face_mesh_detection.dart';

class FaceMeshService {
  final FaceMeshDetector _meshDetector = FaceMeshDetector(option: FaceMeshDetectorOptions.faceMesh);
  
  bool _isBusy = false;

  Future<List<FaceMesh>> processImage(CameraImage image, int sensorOrientation, CameraDescription camera) async {
    if (_isBusy) return [];
    if (kIsWeb) return []; // Not supported on Web
    _isBusy = true;

    final inputImage = _inputImageFromCameraImage(image, sensorOrientation, camera);
    if (inputImage == null) {
      _isBusy = false;
      return [];
    }

    try {
      final List<FaceMesh> meshes = await _meshDetector.processImage(inputImage);
      return meshes;
    } catch (e) {
      print("Error detecting face mesh: $e");
      return [];
    } finally {
      _isBusy = false;
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image, int sensorOrientation, CameraDescription camera) {
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    final plane = image.planes.first;
    
    // Concatenate planes for NV21/YUV420 etc logic would be more complex
    // keeping it simple for now, usually MLKit helper libraries handle this best
    // But for raw implementation:
    
    return InputImage.fromBytes(
      bytes: _concatenatePlanes(image.planes),
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: _getImageRotation(sensorOrientation, camera),
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final allBytes = WriteBuffer();
    for (var plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  InputImageRotation _getImageRotation(int sensorOrientation, CameraDescription camera) {
    // simplified rotation logic
    return InputImageRotation.rotation270deg; // Common for portrait
  }

  void dispose() {
    _meshDetector.close();
  }
}
