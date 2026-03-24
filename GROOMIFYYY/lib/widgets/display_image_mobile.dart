import 'dart:io';
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
    return Image.file(
      File(path),
      width: width,
      height: height,
      fit: fit ?? BoxFit.cover,
    );
  }
}
