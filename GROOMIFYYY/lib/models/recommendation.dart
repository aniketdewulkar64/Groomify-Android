import 'face_shape.dart';

class Recommendation {
  final int? id;
  final int? userId;
  final FaceShape faceShape;
  final List<String> hairstyles;
  final List<String> beardStyles;
  final int rating;
  final String? imagePath;
  final DateTime createdAt;

  Recommendation({
    this.id,
    this.userId,
    required this.faceShape,
    required this.hairstyles,
    required this.beardStyles,
    required this.rating,
    this.imagePath,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'faceShape': faceShape.name,
      'hairstyles': hairstyles.join(','),
      'beardStyles': beardStyles.join(','),
      'rating': rating,
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Recommendation.fromMap(Map<String, dynamic> map) {
    return Recommendation(
      id: map['id'] as int?,
      userId: map['userId'] as int?,
      faceShape: FaceShape.values.firstWhere(
        (e) => e.name == map['faceShape'],
        orElse: () => FaceShape.oval,
      ),
      hairstyles: (map['hairstyles'] as String).split(','),
      beardStyles: (map['beardStyles'] as String).split(','),
      rating: map['rating'] as int,
      imagePath: map['imagePath'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}

