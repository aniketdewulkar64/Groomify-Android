enum FaceShape {
  oval,
  round,
  square,
  triangle,
  heart,
  diamond,
}

extension FaceShapeExtension on FaceShape {
  String get displayName {
    switch (this) {
      case FaceShape.oval:
        return 'Oval';
      case FaceShape.round:
        return 'Round';
      case FaceShape.square:
        return 'Square';
      case FaceShape.triangle:
        return 'Triangle';
      case FaceShape.heart:
        return 'Heart';
      case FaceShape.diamond:
        return 'Diamond';
    }
  }

  String get emoji {
    switch (this) {
      case FaceShape.oval:
        return '🥚'; // More appropriate for oval
      case FaceShape.round:
        return '⭕';
      case FaceShape.square:
        return '🟦';
      case FaceShape.triangle:
        return '🔺';
      case FaceShape.heart:
        return '❤️';
      case FaceShape.diamond:
        return '💎';
    }
  }
}

class FaceShapeResult {
  final FaceShape shape;
  final double confidence;
  final FaceShape? secondaryShape;
  final double? secondaryConfidence;
  final int rating;
  final Map<String, double> measurements;
  final Map<String, List<double>> landmarks; // {'leftEye': [x,y], ...}
  final Map<FaceShape, double> scores; // Added to show comparison
  final DateTime detectedAt;

  FaceShapeResult({
    required this.shape,
    required this.confidence,
    this.secondaryShape,
    this.secondaryConfidence,
    required this.rating,
    required this.measurements,
    required this.landmarks,
    required this.scores,
    required this.detectedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'shape': shape.name,
      'confidence': confidence,
      'secondaryShape': secondaryShape?.name,
      'secondaryConfidence': secondaryConfidence,
      'rating': rating,
      'measurements': measurements,
      'landmarks': landmarks,
      'scores': scores.map((k, v) => MapEntry(k.name, v)),
      'detectedAt': detectedAt.toIso8601String(),
    };
  }

  factory FaceShapeResult.fromMap(Map<String, dynamic> map) {
    // Helper to parse scores
    final Map<FaceShape, double> parsedScores = {};
    if (map['scores'] != null) {
      (map['scores'] as Map).forEach((k, v) {
        final shape = FaceShape.values.firstWhere((e) => e.name == k, orElse: () => FaceShape.oval);
        parsedScores[shape] = (v as num).toDouble();
      });
    }

    return FaceShapeResult(
      shape: FaceShape.values.firstWhere(
        (e) => e.name == map['shape'],
        orElse: () => FaceShape.oval,
      ),
      confidence: (map['confidence'] as num).toDouble(),
      secondaryShape: map['secondaryShape'] != null
          ? FaceShape.values.firstWhere(
              (e) => e.name == map['secondaryShape'],
              orElse: () => FaceShape.oval,
            )
          : null,
      secondaryConfidence: (map['secondaryConfidence'] as num?)?.toDouble(),
      rating: map['rating'] as int,
      measurements: Map<String, double>.from(map['measurements'] as Map),
      landmarks: (map['landmarks'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, List<double>.from(v)),
          ) ??
          {},
      scores: parsedScores,
      detectedAt: DateTime.parse(map['detectedAt'] as String),
    );
  }
}
