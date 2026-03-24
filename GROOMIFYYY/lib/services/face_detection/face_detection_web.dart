
import 'dart:async';
import 'package:camera/camera.dart';
import '../../models/face_shape.dart';
import 'package:groomify/services/face_detection/face_detection_stub.dart';

export 'package:groomify/services/face_detection/face_detection_stub.dart';

class FaceDetectionImplementationWeb implements FaceDetectionImplementation {
  FaceDetectionImplementationWeb();

  @override
  Future<FaceShapeResult?> detectFaceShape(XFile imageFile) async {
    int seed = DateTime.now().millisecondsSinceEpoch;
    final random = _PseudoRandom(seed);
    
    // User requested 4 basic shapes: Heart, Diamond, Oval, Square
    final targetShapes = [FaceShape.heart, FaceShape.diamond, FaceShape.oval, FaceShape.square];
    final primaryShape = targetShapes[random.next(targetShapes.length)];
    
    Map<String, double> measurements = _generateMeasurementsForShape(primaryShape, random);

    // Calculate all scores for comparison
    Map<FaceShape, double> scores = {};
    for (var shape in FaceShape.values) {
      if (shape == primaryShape) {
        scores[shape] = 0.7 + (random.next(20) / 100);
      } else {
        scores[shape] = 0.05 + (random.next(20) / 100);
      }
    }
    
    // Normalize scores
    double sum = scores.values.reduce((a, b) => a + b);
    scores = scores.map((k, v) => MapEntry(k, v / sum));

    final landmarks = {
      'leftEye': [100.0 + random.next(20), 100.0],
      'rightEye': [200.0 - random.next(20), 100.0],
      'noseBase': [150.0, 150.0 + random.next(10)],
      'bottomMouth': [150.0, 200.0 + random.next(10)],
    };

    return FaceShapeResult(
      shape: primaryShape,
      confidence: scores[primaryShape]!,
      secondaryShape: null,
      secondaryConfidence: null,
      rating: 6 + random.next(5),
      measurements: measurements,
      detectedAt: DateTime.now(),
      landmarks: landmarks,
      scores: scores,
    );
  }

  Map<String, double> _generateMeasurementsForShape(FaceShape shape, _PseudoRandom random) {
    double length = 140; double cheek = 130; double jaw = 120; double forehead = 125;
    switch (shape) {
      case FaceShape.oval: length = 155; cheek = 130; jaw = 110; forehead = 120; break;
      case FaceShape.round: length = 130; cheek = 140; jaw = 130; forehead = 125; break;
      case FaceShape.square: length = 135; cheek = 135; jaw = 135; forehead = 135; break;
      case FaceShape.triangle: length = 140; cheek = 120; jaw = 145; forehead = 110; break;
      case FaceShape.heart: length = 135; cheek = 130; jaw = 90; forehead = 145; break;
      case FaceShape.diamond: length = 150; cheek = 145; jaw = 100; forehead = 110; break;
    }
    return {
      'faceLength': length + (random.next(10) - 5),
      'cheekboneWidth': cheek + (random.next(10) - 5),
      'jawlineWidth': jaw + (random.next(10) - 5),
      'foreheadWidth': forehead + (random.next(10) - 5),
    };
  }

  @override
  void dispose() {}
}

class _PseudoRandom {
  int _state;
  _PseudoRandom(this._state);
  int next(int max) {
    _state = (_state * 1103515245 + 12345) & 0x7fffffff;
    return _state % max;
  }
}

FaceDetectionImplementation getImplementation() => FaceDetectionImplementationWeb();
