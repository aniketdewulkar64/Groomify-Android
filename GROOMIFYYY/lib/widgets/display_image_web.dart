import 'package:flutter/material.dart';

class DisplayImage extends StatelessWidget {
  final String path;
  final double? width;
  final double? height;
  final BoxFit? fit;

  const DisplayImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit,
  });

  @override
  Widget build(BuildContext context) {
    // On Web, the XFile path is a blob URL which works with Image.network
    return Image.network(
      path,
      width: width,
      height: height,
      fit: fit ?? BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey, 
            width: width, 
            height: height,
            child: const Icon(Icons.broken_image, color: Colors.white),
          );
      },
    );
  }
}
