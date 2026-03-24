import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_mesh_detection/google_mlkit_face_mesh_detection.dart';
import 'package:groomify/services/face_detection/face_mesh_service.dart';
import 'package:groomify/services/ar/ar_module_interface.dart';
import 'package:groomify/services/ar/beard_module.dart';
import 'package:groomify/services/ar/hairstyle_module.dart';
import 'package:groomify/widgets/ar_painter.dart';

class CameraARScreen extends StatefulWidget {
  const CameraARScreen({super.key});

  @override
  State<CameraARScreen> createState() => _CameraARScreenState();
}

class _CameraARScreenState extends State<CameraARScreen> {
  CameraController? _controller;
  final FaceMeshService _faceMeshService = FaceMeshService();
  List<FaceMesh> _faces = [];
  bool _isDetecting = false;

  final List<ARModule> _activeModules = [];

  // Assuming you initialize cameras elsewhere or fetch them here
  List<CameraDescription> cameras = [];

  @override
  void initState() {
    super.initState();
    
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context, 
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text("Mobile Only Feature"),
            content: const Text("The AR Grooming Studio requires native Face Mesh libraries which are not supported in the browser. Please use the mobile app."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close screen
                }, 
                child: const Text("Go Back")
              )
            ],
          )
        );
      });
      return; 
    }

    _initializeCamera();
    
    // Default modules for testing
    _activeModules.add(BeardModule());
    _activeModules.add(HairstyleModule());
  }

  Future<void> _initializeCamera() async {
    cameras = await availableCameras();
    if (cameras.isEmpty) return;
    
    // Use front camera
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21, // Best for Android/MLKit
    );

    await _controller!.initialize();
    
    if (mounted) {
      setState(() {});
      _startImageStream();
    }
  }

  void _startImageStream() {
    _controller?.startImageStream((image) async {
       if (_isDetecting) return;
       _isDetecting = true;
       
       try {
         final faces = await _faceMeshService.processImage(
           image, 
           _controller!.description.sensorOrientation,
           _controller!.description
         );
         
         if (mounted) {
           setState(() {
             _faces = faces;
           });
         }
       } finally {
         _isDetecting = false;
       }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _faceMeshService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final size = MediaQuery.of(context).size;
    var scale = size.aspectRatio * _controller!.value.aspectRatio;

    // fix for scaling if needed
    if (scale < 1) scale = 1 / scale;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Transform.scale(
            scale: scale,
            child: Center(
              child: CameraPreview(_controller!),
            ),
          ),
          
          if (_faces.isNotEmpty)
             CustomPaint(
               painter: ARPainter(
                 faces: _faces,
                 activeModules: _activeModules,
                 absoluteImageSize: Size(
                   _controller!.value.previewSize!.height, 
                   _controller!.value.previewSize!.width
                 ),
                 rotation: InputImageRotation.rotation270deg,
               ),
             ),
             
          // Filter Tray Placeholder
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Container(
              height: 100,
              color: Colors.transparent, 
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFilterIcon("Beard", Icons.face),
                  _buildFilterIcon("Hair", Icons.face_retouching_natural),
                ],
              ),
            ),
          ),
          
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          )
        ],
      ),
    );
  }
  
  Widget _buildFilterIcon(String label, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white.withOpacity(0.3),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
