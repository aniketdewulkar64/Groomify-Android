import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:groomify/models/face_shape.dart';

import 'package:groomify/services/face_detection/face_detection_stub.dart'
    if (dart.library.io) 'face_detection_mobile.dart'
    if (dart.library.js_interop) 'face_detection_web.dart' as impl;

class FaceDetectionService {
  static final FaceDetectionService instance = FaceDetectionService._init();

  late final impl.FaceDetectionImplementation _implementation;

  FaceDetectionService._init() {
    _implementation = impl.getImplementation();
  }

  // Caching mechanism
  FaceShapeResult? _cachedResult;
  String? _cachedImagePath;
  
  FaceShapeResult? get cachedResult => _cachedResult;
  String? get cachedImagePath => _cachedImagePath;

  Future<void> loadFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString('face_shape_result');
      final String? imagePath = prefs.getString('face_image_path');

      if (jsonString != null && imagePath != null) {
        _cachedResult = FaceShapeResult.fromMap(json.decode(jsonString));
        _cachedImagePath = imagePath;
      }
    } catch (e) {
      debugPrint('Error loading face data: $e');
    }
  }

  Future<void> saveToPreferences(FaceShapeResult result, String imagePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('face_shape_result', json.encode(result.toMap()));
      await prefs.setString('face_image_path', imagePath);
      
      _cachedResult = result;
      _cachedImagePath = imagePath;
    } catch (e) {
      debugPrint('Error saving face data: $e');
    }
  }

  void setCachedResult(FaceShapeResult result, String imagePath) {
    _cachedResult = result;
    _cachedImagePath = imagePath;
    saveToPreferences(result, imagePath);
  }
  
  Future<void> clearCache() async {
    _cachedResult = null;
    _cachedImagePath = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('face_shape_result');
    await prefs.remove('face_image_path');
  }

  Future<FaceShapeResult?> detectFaceShape(XFile imageFile) async {
    final result = await _implementation.detectFaceShape(imageFile);
    if (result != null) {
      await saveToPreferences(result, imageFile.path);
    }
    return result;
  }

  void dispose() {
    _implementation.dispose();
  }
}
