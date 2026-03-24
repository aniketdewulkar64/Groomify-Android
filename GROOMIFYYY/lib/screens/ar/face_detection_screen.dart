import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:groomify/services/face_detection/face_detection_service.dart';
import 'package:groomify/models/face_shape.dart';
import 'package:groomify/config/theme.dart';
import 'package:groomify/screens/recommendations/suggestion_screen.dart';

class FaceDetectionScreen extends StatefulWidget {
  final bool isGuest;
  final int? userId;
  final bool showHairstylesOnly;
  final bool showBeardsOnly;

  const FaceDetectionScreen({
    super.key,
    required this.isGuest,
    this.userId,
    this.showHairstylesOnly = false,
    this.showBeardsOnly = false,
  });

  @override
  State<FaceDetectionScreen> createState() => _FaceDetectionScreenState();
}

class _FaceDetectionScreenState extends State<FaceDetectionScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  int _selectedCameraIndex = 0;
  // ... (existing vars)
  bool _isDetecting = false;
  bool _isLoading = true; // Start with loading state
  FaceShapeResult? _detectionResult;
  XFile? _capturedImage;

  @override
  void initState() {
    super.initState();
    _checkSavedDataAndInit();
  }

  Future<void> _checkSavedDataAndInit() async {
    // Only check cache if we are in a "Suggestor" mode (not explicit "Face Shape Detector" tool)
    // BUT user requested "dynamic everytime", so we disable auto-load.
    // Disabled auto-load to prevent navigation loops and ensure dynamic detection every time.
    // if (widget.showHairstylesOnly || widget.showBeardsOnly) {
    //    await FaceDetectionService.instance.loadFromPreferences();
    //    if (mounted && 
    //        FaceDetectionService.instance.cachedResult != null && 
    //        FaceDetectionService.instance.cachedImagePath != null) {
    //        _onDetectionSuccess(
    //          FaceDetectionService.instance.cachedResult!, 
    //          null, 
    //          replaceStack: true
    //        );
    //        return; 
    //    }
    // }
    
    // If no cache or not in suggestor mode, init camera
    if (mounted) {
      setState(() => _isLoading = false); // Stop loading to show camera init
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    // ... existing init logic ...
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No camera available', style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      int frontIndex = _cameras!.indexWhere((c) => c.lensDirection == CameraLensDirection.front);
      _selectedCameraIndex = frontIndex != -1 ? frontIndex : 0;

      await _initCamera(_cameras![_selectedCameraIndex]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera error: $e', style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _initCamera(CameraDescription description) async {
    final controller = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: !kIsWeb && defaultTargetPlatform == TargetPlatform.android 
          ? ImageFormatGroup.jpeg 
          : ImageFormatGroup.bgra8888,
    );

    _cameraController = controller;

    try {
      await controller.initialize();
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      debugPrint("Camera initialization failed: $e");
    }
  }

  Future<void> _toggleCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    setState(() {
      _isInitialized = false;
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;
    });

    await _cameraController?.dispose();
    await _initCamera(_cameras![_selectedCameraIndex]);
  }

  Future<void> _captureAndDetect() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() => _isDetecting = true);

    try {
      final image = await _cameraController!.takePicture();
      setState(() => _capturedImage = image);

      // Detect face shape - pass XFile directly
      final result = await FaceDetectionService.instance.detectFaceShape(image);

      if (mounted) {
        setState(() {
          _detectionResult = result;
          _isDetecting = false;
        });

        if (result != null) {
          _onDetectionSuccess(result, image, replaceStack: false);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No face detected. Please try again.', style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.orange,
            ),
          );
          setState(() => _isDetecting = false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Detection error: $e', style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isDetecting = false);
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  void _onDetectionSuccess(FaceShapeResult result, XFile? image, {bool replaceStack = false}) {
      setState(() {
        _detectionResult = result;
        _isDetecting = false;
        if (image != null) _capturedImage = image;
      });
      
      final imagePath = image?.path ?? FaceDetectionService.instance.cachedImagePath ?? '';

      if (replaceStack) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SuggestionScreen(
              faceShapeResult: result,
              imagePath: imagePath,
              isGuest: widget.isGuest,
              userId: widget.userId,
              showHairstylesOnly: widget.showHairstylesOnly,
              showBeardsOnly: widget.showBeardsOnly,
            ),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SuggestionScreen(
              faceShapeResult: result,
              imagePath: imagePath,
              isGuest: widget.isGuest,
              userId: widget.userId,
              showHairstylesOnly: widget.showHairstylesOnly,
              showBeardsOnly: widget.showBeardsOnly,
            ),
          ),
        );
      }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          widget.showHairstylesOnly
              ? 'Hairstyle Suggestor'
              : widget.showBeardsOnly
                  ? 'Beard Suggestor'
                  : 'Face Shape Detector',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppTheme.premiumDark),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.premiumDark),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.goldenGradient,
        ),
        child: Column(
          children: [
            // Spacer for transparent AppBar
            const SizedBox(height: 100),
            
            // Camera Preview
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: _isLoading 
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: AppTheme.premiumDark),
                              SizedBox(height: 16),
                              Text("Checking saved face data...", style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        )
                      : _isInitialized && _cameraController != null
                      ? Stack(
                          alignment: Alignment.center,
                          children: [
                            CameraPreview(_cameraController!),
                            // Face detection overlay guide
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final guideWidth = constraints.maxWidth > 400 
                                    ? 250.0 
                                    : constraints.maxWidth * 0.7;
                                final guideHeight = guideWidth * 1.2;
                                return Container(
                                  width: guideWidth,
                                  height: guideHeight,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                );
                              },
                            ),
                            Positioned(
                              bottom: 40,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Position your face in the frame',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            if (_cameras != null && _cameras!.length > 1)
                              Positioned(
                                top: 20,
                                right: 20,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _toggleCamera,
                                    borderRadius: BorderRadius.circular(30),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.black26,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white54),
                                      ),
                                      child: const Icon(
                                        Icons.cameraswitch,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        )
                      : const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.premiumDark,
                          ),
                        ),
                ),
              ),
            ),

            // Controls
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: _isDetecting || !_isInitialized
                          ? null
                          : _captureAndDetect,
                      icon: _isDetecting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.camera_alt, size: 28),
                      label: Text(
                        _isDetecting ? 'Analyzing Face...' : 'Detect Face Shape',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.premiumDark,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Make sure your face is well-lit and clearly visible',
                    style: GoogleFonts.poppins(
                      color: AppTheme.premiumDarkText.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

