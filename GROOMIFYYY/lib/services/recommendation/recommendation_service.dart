import 'package:groomify/models/face_shape.dart';

class StyleRecommendation {
  final String name;
  final double matchScore; // 0.0 to 1.0
  final String reason;
  final String imageUrl;
  final String category; // 'Short', 'Medium', 'Long', 'Stubble', 'Full'

  const StyleRecommendation({
    required this.name,
    required this.matchScore,
    this.reason = '',
    String? imageUrl,
    required this.category,
  }) : imageUrl = imageUrl ?? 'https://placehold.co/200x200/png?text=$name';
}

class RecommendationService {
  static final RecommendationService instance = RecommendationService._init();
  RecommendationService._init();

  List<StyleRecommendation> getHairstyleRecommendations(FaceShapeResult result) {
    final shape = result.shape;
    final measurements = result.measurements;
    
    // Base list based on shape
    List<StyleRecommendation> baseList = _getBaseHairstyles(shape);
    baseList.shuffle(); // Randomize variations order before scoring
    
    // Dynamic Adjustment based on exact measurements
    return baseList.map((style) {
      double adjustedScore = _calculateDynamicScore(
        style.matchScore,
        style.name,
        measurements,
        isBeard: false,
      );
      
      // Update reason based on score impact
      String reason = style.reason;
      double diff = adjustedScore - style.matchScore;
      
      if (diff > 0.05) {
        reason = "Perfectly balances your facial ratios";
      } else if (diff > 0.02) {
        reason = "Complements your features well";
      } else if (diff < -0.05) {
        reason = "May emphasize features you want to balance";
      }
      
      // Override reason if specific logic triggers
      if (measurements['faceLength']! / measurements['cheekboneWidth']! > 1.5 && 
          (style.name.contains('Volume') || style.name.contains('Pompadour'))) {
         reason = "Adds height but use with caution on long faces";
      }

      return StyleRecommendation(
        name: style.name,
        matchScore: adjustedScore.clamp(0.0, 0.99),
        reason: reason,
        imageUrl: style.imageUrl,
        category: style.category,
      );
    }).toList()
      ..sort((a, b) => b.matchScore.compareTo(a.matchScore)); // Sort by new score
  }

  List<StyleRecommendation> getBeardRecommendations(FaceShapeResult result) {
    final shape = result.shape;
    final measurements = result.measurements;
    
    List<StyleRecommendation> baseList = _getBaseBeards(shape);
    baseList.shuffle(); // Randomize variations order before scoring
    
    return baseList.map((style) {
      double adjustedScore = _calculateDynamicScore(
        style.matchScore,
        style.name,
        measurements,
        isBeard: true,
      );

      String reason = style.reason;
      if (adjustedScore > style.matchScore) {
          reason = "Great for defining your jawline";
      }
      
      return StyleRecommendation(
        name: style.name,
        matchScore: adjustedScore.clamp(0.0, 0.99),
        reason: reason,
        imageUrl: style.imageUrl,
        category: style.category,
      );
    }).toList()
      ..sort((a, b) => b.matchScore.compareTo(a.matchScore));
  }

  double _calculateDynamicScore(double base, String name, Map<String, double> m, {required bool isBeard}) {
    if (m.isEmpty) return base;
    
    double score = base;
    
    // Ratios
    double length = m['faceLength'] ?? 100;
    double width = m['cheekboneWidth'] ?? 100;
    double jaw = m['jawlineWidth'] ?? 100;
    
    double lengthRatio = length / (width == 0 ? 1 : width); // Avoid div by 0
    double jawRatio = jaw / (width == 0 ? 1 : width);

    // GOLDEN RATIO LOGIC integration
    // Ideal face ratio (Length/Width) is approx 1.618 (Phi)
    // We adjust the score based on how much the style helps achieve this perception.
    double deviationFromPhi = (lengthRatio - 1.618).abs();
    
    // If deviation is small (< 0.1), the face is naturally "aesthetic" by this standard.
    // We boost styles that maintain this.
    if (deviationFromPhi < 0.1) {
       score += 0.05; 
    }

    if (!isBeard) {
      // HAIRSTYLE LOGIC
      bool addsHeight = name.contains('Pompadour') || name.contains('Quiff') || name.contains('Volume') || name.contains('Hawk');
      bool addsWidth = name.contains('Flow') || name.contains('Part') || name.contains('Fringe') || name.contains('Crop');
      
      // If face is shorter than Phi (< 1.6), we need HEIGHT to approach 1.6
      if (lengthRatio < 1.5) {
         if (addsHeight) score += 0.12; // increased boost
      }
      
      // If face is longer than Phi (> 1.7), we need WIDTH to lower the ratio perception
      if (lengthRatio > 1.7) {
         if (addsWidth) score += 0.12;
         if (addsHeight) score -= 0.05; // Penalize height slightly
      }
    } else {
      // BEARD LOGIC
      bool sharp = name.contains('Van Dyke') || name.contains('Anchor') || name.contains('Goatee') || name.contains('Ducktail');
      bool full = name.contains('Full') || name.contains('Garibaldi') || name.contains('Chops');
      
      // If jaw is narrow relative to Golden Ratio aesthetics, broaden it
      if (jawRatio < 0.8 && full) {
        score += 0.10;
      }
      
      // If face is round/short, sharp vertical lines help elongate towards Phi
      if (lengthRatio < 1.4 && sharp) {
        score += 0.10;
      }
    }
    
    return score;
  }
  
  // New Helper for UI visualization
  double calculateGoldenRatioValues(Map<String, double> m) {
     if (m.isEmpty) return 0.0;
     double length = m['faceLength'] ?? 100;
     double width = m['cheekboneWidth'] ?? 100;
     return length / (width == 0 ? 1 : width);
  }

  // --- Base Lists ---
  // --- Base Lists ---
  List<StyleRecommendation> _getBaseHairstyles(FaceShape shape) {
    const String assetPath = 'assets/images/stickers';
    
    // MASTER LIST of all available hairstyles
    // We define them here once, and then assign base scores based on the shape.
    final allStyles = [
       // Male Hairstyles
       {'name': 'Male - Textured Fade', 'cat': 'Short', 'img': '$assetPath/male_hair1.png'},
       {'name': 'Male - Modern Spiky', 'cat': 'Short', 'img': '$assetPath/male_hair2.png'},
       {'name': 'Male - Casual Layered', 'cat': 'Medium', 'img': '$assetPath/hair_male3.png'},
       {'name': 'Male - Side Swept', 'cat': 'Medium', 'img': '$assetPath/male_hair4.png'},
       {'name': 'Male - Slick Back', 'cat': 'Medium', 'img': '$assetPath/male_hair5.png'},
       {'name': 'Male - Curly Top', 'cat': 'Medium', 'img': '$assetPath/male_hair6.png'},
       
       // Female Hairstyles
       {'name': 'Female - Long Waves', 'cat': 'Long', 'img': '$assetPath/female_hair1.png'},
       {'name': 'Female - Thick Quiff', 'cat': 'Medium', 'img': '$assetPath/female_hair2.png'},
       {'name': 'Female - Bob Cut', 'cat': 'Short', 'img': '$assetPath/female_hair3.png'},
       {'name': 'Female - Soft Curls', 'cat': 'Medium', 'img': '$assetPath/female_hair4.png'},
       {'name': 'Female - Straight Long', 'cat': 'Long', 'img': '$assetPath/female_hair5.png'},
       {'name': 'Female - Edgy Messy', 'cat': 'Medium', 'img': '$assetPath/female_hair6.png'},
    ];

    List<StyleRecommendation> recommendations = [];

    for (var styleData in allStyles) {
       String name = styleData['name']!;
       String category = styleData['cat']!;
       String img = styleData['img']!;
       
       double baseScore = 0.5; // Default "Okay" score
       String reason = "Available for try-on";

       // Shape-Specific Logic (The "Expert Knowledge" Base)
       switch (shape) {
         case FaceShape.oval:
            // Oval suits almost everything
            baseScore = 0.85;
            if (name.contains('Side Swept') || name.contains('Side Part')) baseScore = 0.95;
            if (name.contains('Quiff')) baseScore = 0.94;
            if (name.contains('Slick Back')) baseScore = 0.92;
            if (name.contains('Long') || name.contains('Waves')) baseScore = 0.90; // Good for female oval
            break;
            
         case FaceShape.round:
            // Needs height/angles. Avoid width.
            if (name.contains('Pompadour') || name.contains('Spiky') || name.contains('Quiff') || name.contains('Volume')) {
              baseScore = 0.95;
              reason = "Adds vertical height to balance roundness";
            } else if (name.contains('Slick') || name.contains('Fade') || name.contains('Straight')) {
              baseScore = 0.85;
            } else if (name.contains('Bob') || name.contains('Curls')) {
               baseScore = 0.60;
               reason = "Might add unwanted width";
            } else {
              baseScore = 0.60;
              reason = "Might add unwanted width";
            }
            break;
            
         case FaceShape.square:
            // Needs softening or emphasizing masculinity.
            if (name.contains('Fade') || name.contains('Slick') || name.contains('Bob')) {
              baseScore = 0.95; 
              reason = styleData['name']!.contains('Male') ? "Highlights strong jawline" : "Accentuates jawline structure";
            } else if (name.contains('Messy') || name.contains('Side') || name.contains('Waves')) {
               baseScore = 0.90;
               reason = "Softens strong angles";
            } else {
               baseScore = 0.70;
            }
            break;
            
         case FaceShape.diamond:
            // Needs width at forehead/chin. avoiding height if face is long.
            if (name.contains('Side') || name.contains('Curly') || name.contains('Layered') || name.contains('Waves')) {
               baseScore = 0.94;
               reason = "Balances cheekbones";
            } else if (name.contains('Fade') || name.contains('Bob')) {
               baseScore = 0.85;
            } else {
               baseScore = 0.75;
            }
            break;
            
         case FaceShape.heart:
             // Wide forehead, narrow chin. Needs balance.
             if (name.contains('Side') || name.contains('Layered') || name.contains('Long')) {
                baseScore = 0.95;
                reason = "Softens forehead width";
             } else if (name.contains('Part') || name.contains('Quiff') || name.contains('Bob')) {
                baseScore = 0.90;
             } else {
                baseScore = 0.70;
             }
             break;
             
         case FaceShape.triangle:
             // Narrow forehead. Needs volume on top/sides.
             if (name.contains('Quiff') || name.contains('Curly') || name.contains('Pompadour') || name.contains('Messy')) {
                baseScore = 0.94;
                reason = "Adds needed volume on top";
             } else if (name.contains('Swept') || name.contains('Waves')) {
                baseScore = 0.88;
             } else {
                baseScore = 0.70;
             }
             break;
       }

       recommendations.add(
         StyleRecommendation(
           name: name,
           matchScore: baseScore,
           category: category,
           imageUrl: img,
           reason: reason,
         )
       );
    }
    
    return recommendations;
  }

  List<StyleRecommendation> _getBaseBeards(FaceShape shape) {
    const String assetPath = 'assets/images/stickers';
    
    // Assets Available:
    // beard_small.png (Stubble)
    // beard_ducktail.png (Ducktail/Pointed)
    // blackfullbeard.png (Full/Thick)

    switch (shape) {
       case FaceShape.oval:
        return [
          StyleRecommendation(name: 'Ducktail', matchScore: 0.94, category: 'Short', imageUrl: '$assetPath/beard_male1.png'),
          StyleRecommendation(name: 'Light Stubble', matchScore: 0.90, category: 'Stubble', imageUrl: '$assetPath/beard_male2.png'),
          StyleRecommendation(name: 'Full Beard', matchScore: 0.88, category: 'Full', imageUrl: '$assetPath/beard_male3.png'),
        ];
      case FaceShape.round:
        return [
           StyleRecommendation(name: 'Ducktail', matchScore: 0.96, reason: 'Elongates round face', category: 'Full', imageUrl: '$assetPath/beard_male1.png'),
           StyleRecommendation(name: 'Volume Beard', matchScore: 0.91, category: 'Full', imageUrl: '$assetPath/beard_male5.png'),
           StyleRecommendation(name: 'Full Beard', matchScore: 0.85, category: 'Full', imageUrl: '$assetPath/beard_male3.png'),
        ];
      case FaceShape.square:
        return [
          StyleRecommendation(name: 'Classic Stubble', matchScore: 0.93, category: 'Stubble', imageUrl: '$assetPath/beard_male4.png'),
          StyleRecommendation(name: 'Ducktail', matchScore: 0.90, category: 'Short', imageUrl: '$assetPath/beard_male1.png'),
          StyleRecommendation(name: 'Full Beard', matchScore: 0.89, category: 'Full', imageUrl: '$assetPath/beard_male3.png'),
        ];
      case FaceShape.diamond:
        return [
          StyleRecommendation(name: 'Full Beard', matchScore: 0.95, category: 'Full', imageUrl: '$assetPath/beard_male3.png'),
          StyleRecommendation(name: 'Ducktail', matchScore: 0.91, category: 'Short', imageUrl: '$assetPath/beard_male1.png'),
          StyleRecommendation(name: 'Light Stubble', matchScore: 0.87, category: 'Stubble', imageUrl: '$assetPath/beard_male2.png'),
        ];
      case FaceShape.heart:
        return [
          StyleRecommendation(name: 'Full Beard', matchScore: 0.96, category: 'Full', imageUrl: '$assetPath/beard_male3.png'),
          StyleRecommendation(name: 'Ducktail', matchScore: 0.92, category: 'Full', imageUrl: '$assetPath/beard_male1.png'),
          StyleRecommendation(name: 'Light Stubble', matchScore: 0.88, category: 'Stubble', imageUrl: '$assetPath/beard_male2.png'),
        ];
      case FaceShape.triangle:
        return [
          StyleRecommendation(name: 'Light Stubble', matchScore: 0.93, category: 'Short', imageUrl: '$assetPath/beard_male2.png'),
          StyleRecommendation(name: 'Full Beard', matchScore: 0.90, category: 'Full', imageUrl: '$assetPath/beard_male3.png'),
          StyleRecommendation(name: 'Volume Beard', matchScore: 0.88, category: 'Full', imageUrl: '$assetPath/beard_male5.png'),
        ];
    }
  }
}
