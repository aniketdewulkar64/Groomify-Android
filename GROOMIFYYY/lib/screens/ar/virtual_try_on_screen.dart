import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gal/gal.dart';
import 'package:groomify/widgets/display_image.dart';
import 'package:groomify/config/theme.dart';

import 'package:groomify/services/recommendation/recommendation_service.dart';

class VirtualTryOnScreen extends StatefulWidget {
  final String imagePath;
  final List<StyleRecommendation> allStyles;
  final int initialIndex;
  final Map<String, List<double>> landmarks;

  const VirtualTryOnScreen({
    super.key,
    required this.imagePath,
    required this.allStyles,
    required this.initialIndex,
    required this.landmarks,
  });

  @override
  State<VirtualTryOnScreen> createState() => _VirtualTryOnScreenState();
}

class _VirtualTryOnScreenState extends State<VirtualTryOnScreen> {
  final GlobalKey _repaintKey = GlobalKey();
  // Scaling factors
  // Filter adjustments
  double _opacity = 1.0;
  double _colorIntensity = 1.0;
  Color _filterColor = Colors.white; // Default to white (Original) for Modulate logic

  // Transform variables
  Offset _offset = Offset.zero;
  double _scale = 1.0;
  double _rotation = 0.0;
  
  // State
  late int _currentIndex;
  bool _controlsVisible = false; // Collapsed by default to show full image
  
  // Base values for gesture updates
  Offset _baseOffset = Offset.zero;
  Offset _startFocalPoint = Offset.zero;
  double _baseScale = 1.0;
  double _baseRotation = 0.0;

  Size? _imageSize;
  Size? _containerSize;
  bool _hasCalculated = false;

  // Concealer/Eraser State
  bool _isConcealerMode = false;
  final List<List<Offset?>> _strokes = []; // List of strokes (each is a list of points)
  Color _concealerColor = const Color(0xFFFFE0BD); // Default Fair Skin
  final List<List<Offset?>> _strokesBuffer = [];


  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _loadImageSize();
  }

  void _loadImageSize() {
    final ImageProvider provider = Image.network(widget.imagePath).image;
    provider.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        if (mounted) {
          setState(() {
            _imageSize = Size(info.image.width.toDouble(), info.image.height.toDouble());
            _attemptInitialPosition();
          });
        }
      }),
    );
  }

  void _attemptInitialPosition() {
    if (_hasCalculated || _imageSize == null || _containerSize == null || widget.landmarks.isEmpty) return;

    // 1. Calculate Rendered Image Dimensions (BoxFit.contain logic)
    double imageAspectRatio = _imageSize!.width / _imageSize!.height;
    double containerAspectRatio = _containerSize!.width / _containerSize!.height;

    double renderWidth, renderHeight;
    double offsetX, offsetY;

    if (imageAspectRatio > containerAspectRatio) {
      // Constrained by width
      renderWidth = _containerSize!.width;
      renderHeight = renderWidth / imageAspectRatio;
      offsetX = 0;
      offsetY = (_containerSize!.height - renderHeight) / 2;
    } else {
      // Constrained by height
      renderHeight = _containerSize!.height;
      renderWidth = renderHeight * imageAspectRatio;
      offsetX = (_containerSize!.width - renderWidth) / 2;
      offsetY = 0;
    }

    double scaleFactor = renderWidth / _imageSize!.width;

    // 2. Determine Target Landmark
    final currentStyle = widget.allStyles[_currentIndex];
    bool isBeard = currentStyle.category == 'Stubble' || 
                   currentStyle.category == 'Full' ||
                   currentStyle.name.toLowerCase().contains('beard') || 
                   currentStyle.name.toLowerCase().contains('stubble') || 
                   currentStyle.name.toLowerCase().contains('goatee') ||
                   currentStyle.name.toLowerCase().contains('anchor');

    List<double>? target;

    if (isBeard) {
       // For beards, aim for the "noseBase" or halfway between nose and mouth
       var nose = widget.landmarks['noseBase'];
       var mouth = widget.landmarks['bottomMouth'];
       var chin = widget.landmarks['chin'];
       
       if (chin != null) {
          target = [chin[0], chin[1] - 30]; // Position slightly above chin tip
       } else if (nose != null && mouth != null) {
          target = [(nose[0] + mouth[0]) / 2, (nose[1] + mouth[1]) / 2 + 20];
       } else if (nose != null) {
          target = [nose[0], nose[1] + 40]; // Below nose
       } else if (mouth != null) {
          target = mouth;
       }
    } else {
       // For hairstyles, aim for the top of the head/forehead
       var leftEye = widget.landmarks['leftEye'];
       var rightEye = widget.landmarks['rightEye'];
       var nose = widget.landmarks['noseBase'];
       
       if (leftEye != null && rightEye != null && nose != null) {
         // Midpoint of eyes
         double midX = (leftEye[0] + rightEye[0]) / 2;
         double midY = (leftEye[1] + rightEye[1]) / 2;
         
         // Face height estimate
         double faceHeight = (nose[1] - midY).abs() * 2.5; 
         target = [midX, midY - (faceHeight * 0.4)]; // Move up to forehead/hairline
       } else if (leftEye != null && rightEye != null) {
         double midX = (leftEye[0] + rightEye[0]) / 2;
         double midY = (leftEye[1] + rightEye[1]) / 2;
         double eyeDist = (leftEye[0] - rightEye[0]).abs();
         target = [midX, midY - (eyeDist * 1.5)]; 
       }
    }

    if (target != null) {
       // 3. Map Image Coordinates to Screen UI Coordinates
       double screenTargetX = offsetX + (target[0] * scaleFactor);
       double screenTargetY = offsetY + (target[1] * scaleFactor);
       
       // 4. Calculate Offset needed to move the CENTER of the 200x200 overlay to the Screen Target
       double centerX = _containerSize!.width / 2;
       double centerY = _containerSize!.height / 2;
       
       // Calculate Scale
       // Base assumption: Overlay Image is ~200px. We want it to match Face Width.
       double faceWidth = 100.0; // Fallback
       if (widget.landmarks['leftCheek'] != null && widget.landmarks['rightCheek'] != null) {
          faceWidth = (widget.landmarks['leftCheek']![0] - widget.landmarks['rightCheek']![0]).abs();
       } else if (widget.landmarks['leftEye'] != null && widget.landmarks['rightEye'] != null) {
          faceWidth = (widget.landmarks['leftEye']![0] - widget.landmarks['rightEye']![0]).abs() * 2.0; 
       }
       
       double renderedFaceWidth = faceWidth * scaleFactor;
       // Target width for overlay: renderedFaceWidth * Multiplier (Hair is wider than face, Beard is approx face width)
       double targetOverlayWidth = renderedFaceWidth * (isBeard ? 1.2 : 2.0); 
       
       double newScale = targetOverlayWidth / 200.0; // 200 is base width of overlay image
       
       setState(() {
         _offset = Offset(screenTargetX - centerX, screenTargetY - centerY);
         _scale = newScale.clamp(0.2, 5.0);
         _hasCalculated = true;
       });
    }
  }

  Future<void> _saveImage() async {
    try {
      if (_repaintKey.currentContext == null) return;
      
      RenderRepaintBoundary boundary = _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0); 
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        Uint8List pngBytes = byteData.buffer.asUint8List();
        await Gal.putImageBytes(pngBytes);
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("Image saved to gallery!"), backgroundColor: Colors.green)
           );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving: $e"), backgroundColor: Colors.red)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: _isConcealerMode 
            ? Text("Draw to Hide Hair", style: GoogleFonts.poppins(color: Colors.white, fontSize: 16))
            : DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            dropdownColor: Colors.grey[900],
            value: _currentIndex,
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
            items: widget.allStyles.asMap().entries.map((entry) {
               return DropdownMenuItem<int>(
                 value: entry.key,
                 child: Text(entry.value.name, overflow: TextOverflow.ellipsis),
               );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _currentIndex = val;
                  _hasCalculated = false;
                  _filterColor = Colors.white;
                  _colorIntensity = 1.0;
                  _opacity = 1.0;
                  _attemptInitialPosition();
                });
              }
            },
          ),
        ),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
           IconButton(
             icon: Icon(_isConcealerMode ? Icons.check_circle : Icons.brush, color: _isConcealerMode ? Colors.greenAccent : Colors.white),
             onPressed: () => setState(() {
                _isConcealerMode = !_isConcealerMode;
                _controlsVisible = true;
             }),
             tooltip: _isConcealerMode ? "Finish Concealing" : "Conceal Original Hair",
           ),
           if (!_isConcealerMode)
             IconButton(
               icon: Icon(_controlsVisible ? Icons.visibility_off : Icons.tune),
               onPressed: () => setState(() => _controlsVisible = !_controlsVisible),
               tooltip: "Toggle Controls",
             ),
             IconButton(
               icon: const Icon(Icons.download),
               onPressed: _saveImage,
               tooltip: "Save Image",
             )
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (_containerSize == null || _containerSize != Size(constraints.maxWidth, constraints.maxHeight)) {
             _containerSize = Size(constraints.maxWidth, constraints.maxHeight);
             WidgetsBinding.instance.addPostFrameCallback((_) => _attemptInitialPosition());
          }

          return RepaintBoundary(
            key: _repaintKey,
            child: Stack(
              fit: StackFit.expand,
              children: [
              // User Image
              DisplayImage(
                path: widget.imagePath,
                fit: BoxFit.contain,
              ),
              
              // Concealer Layer
              RepaintBoundary(
                child: CustomPaint(
                  painter: _ConcealerPainter(_strokes, _concealerColor),
                  size: Size.infinite,
                ),
              ),
              
              if (_isConcealerMode)
                Positioned.fill(
                  child: GestureDetector(
                    onPanStart: (details) {
                      setState(() {
                        _strokes.add([details.localPosition]);
                        _strokesBuffer.clear();
                      });
                    },
                    onPanUpdate: (details) {
                      setState(() {
                        if (_strokes.isNotEmpty) {
                          _strokes.last.add(details.localPosition);
                        }
                      });
                    },
                    onPanEnd: (_) {
                       setState(() {
                         if (_strokes.isNotEmpty) _strokes.last.add(null);
                       });
                    },
                  ),
                ),

              // Overlay (Draggable & Resizable)
              IgnorePointer(
                ignoring: _isConcealerMode,
                child: Positioned.fill(
                 child: Stack(
                   children: [
                     Positioned(
                       left: constraints.maxWidth / 2 - 100 + _offset.dx,
                       top: constraints.maxHeight / 2 - 100 + _offset.dy,
                       child: GestureDetector(
                         onScaleStart: (details) {
                           _baseOffset = _offset;
                           _baseScale = _scale;
                           _baseRotation = _rotation;
                           _startFocalPoint = details.focalPoint;
                         },
                         onScaleUpdate: (details) {
                           setState(() {
                             // Fix: Use delta from base values instead of cumulative multiplication
                             _scale = (_baseScale * details.scale).clamp(0.2, 5.0);
                             _rotation = _baseRotation + details.rotation;
                             
                             // Calculate offset based on focal point movement relative to start of gesture
                             // This prevents drift and "snap back" issues.
                             _offset = _baseOffset + (details.focalPoint - _startFocalPoint);
                           });
                         },
                         child: Transform.rotate(
                           angle: _rotation,
                           child: Transform.scale(
                             scale: _scale,
                             child: Opacity(
                               opacity: _opacity,
                                child: (_filterColor == Colors.white)
                                    // DIRECT IMAGE RENDERING (No ColorFiltered)
                                    ? ((widget.allStyles[_currentIndex].imageUrl.startsWith('http'))
                                        ? Image.network(
                                            widget.allStyles[_currentIndex].imageUrl,
                                            width: 200,
                                            fit: BoxFit.contain,
                                            filterQuality: FilterQuality.high,
                                            errorBuilder: (c, e, s) => const Icon(Icons.error, color: Colors.red),
                                          )
                                        : Image.asset(
                                            widget.allStyles[_currentIndex].imageUrl,
                                            width: 200,
                                            fit: BoxFit.contain,
                                            filterQuality: FilterQuality.high,
                                            errorBuilder: (c, e, s) => const Icon(Icons.error, color: Colors.red),
                                          ))
                                    // FILTERED RENDERING
                                    : ColorFiltered(
                                        colorFilter: ColorFilter.mode(
                                            _filterColor.withOpacity(_colorIntensity), 
                                            BlendMode.modulate
                                        ),
                                        child: (widget.allStyles[_currentIndex].imageUrl.startsWith('http'))
                                          ? Image.network(
                                              widget.allStyles[_currentIndex].imageUrl,
                                              width: 200,
                                              fit: BoxFit.contain,
                                              filterQuality: FilterQuality.high,
                                              errorBuilder: (c, e, s) => const Icon(Icons.error, color: Colors.red),
                                            )
                                          : Image.asset(
                                              widget.allStyles[_currentIndex].imageUrl,
                                              width: 200,
                                              fit: BoxFit.contain,
                                              filterQuality: FilterQuality.high,
                                              errorBuilder: (c, e, s) => const Icon(Icons.error, color: Colors.red),
                                            ),
                                      ),
                             ),
                           ),
                         ),
                       ),
                     ),
                   ],
                 ),
              ),
            ),
          
          // Controls Panel (Collapsible)
          if (_controlsVisible)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.premiumDark.withOpacity(0.9),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Center(
                         child: Container(
                           width: 40, height: 4, 
                           margin: const EdgeInsets.only(bottom: 16),
                           decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))
                         ),
                       ),
                       // ... (Existing controls)
                       _isConcealerMode ? _buildConcealerControls() : _buildControlContent(),
                    ],
                  ),
                ),
              ),
            ),
        ],
          ),
          );
    }),
    );
  }

  Widget _buildConcealerControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Paint over original hair", style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
            if (_strokes.isNotEmpty)
              TextButton.icon(
                onPressed: () {
                   setState(() {
                      if (_strokes.isNotEmpty) {
                        _strokesBuffer.add(_strokes.removeLast());
                      }
                   });
                }, 
                icon: const Icon(Icons.undo, color: Colors.white70, size: 20),
                label: const Text("Undo", style: TextStyle(color: Colors.white70)),
              )
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildSkinChip(const Color(0xFFFFE0BD), "Fair"),
              _buildSkinChip(const Color(0xFFFFD1AA), "Medium"),
              _buildSkinChip(const Color(0xFFC68642), "Tan"),
              _buildSkinChip(const Color(0xFF8D5524), "Dark"),
              _buildSkinChip(const Color(0xFF5D4037), "Deep"),
            ],
          ),
        )
      ],
    );
  }
  
  Widget _buildSkinChip(Color color, String label) {
    bool isSelected = _concealerColor == color;
    return GestureDetector(
      onTap: () => setState(() => _concealerColor = color),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(3), // Border width
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.greenAccent, width: 2) : null,
        ),
        child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }

  Widget _buildControlContent() {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
                    // Opacity Slider
                    _buildSlider("Transparency", _opacity, (v) => setState(() => _opacity = v)),
                    
                    // Intensity Slider (New)
                    _buildSlider("Color Intensity", _colorIntensity, (v) => setState(() => _colorIntensity = v)),
                    
                    const SizedBox(height: 12),
                    
                    const SizedBox(height: 12),
                    // Color Tints
                    SizedBox(
                      width: double.infinity,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildColorChip("Original", Colors.white),
                            _buildColorChip("Ash", Colors.blueGrey),
                            _buildColorChip("Dark", Colors.grey),
                            _buildColorChip("Brown", const Color(0xFF8D6E63)),
                            _buildColorChip("Blonde", const Color(0xFFFFE082)),
                            _buildColorChip("Auburn", const Color(0xFFFFCCBC)),
                            _buildColorChip("Neon", Colors.purpleAccent),
                          ],
                        ),
                      ),
                    ),
        ]
      );
  }

  Widget _buildSlider(String label, double value, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.accentGold,
              inactiveTrackColor: Colors.white24,
              thumbColor: Colors.white,
              overlayColor: AppTheme.accentGold.withOpacity(0.2),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: value,
              min: 0.1,
              max: 1.0,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorChip(String label, Color color) {
    final effectiveColor = (label == "Original") ? Colors.white : color;
    final isSelected = _filterColor == effectiveColor;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          setState(() {
             _filterColor = effectiveColor;
             _colorIntensity = 1.0; 
          });
        },
        backgroundColor: Colors.white12,
        selectedColor: AppTheme.accentGold,
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.premiumDark : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
        checkmarkColor: AppTheme.premiumDark,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
        showCheckmark: false,
      ),
    );
  }
}

class _ConcealerPainter extends CustomPainter {
  final List<List<Offset?>> strokes;
  final Color color;

  _ConcealerPainter(this.strokes, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 25.0
      ..style = PaintingStyle.stroke
      ..color = color;

    for (final stroke in strokes) {
       List<Offset> points = [];
       for (int i = 0; i < stroke.length; i++) {
         if (stroke[i] == null) {
            if (points.length > 1) {
              canvas.drawPoints(ui.PointMode.polygon, points, paint);
            }
            points.clear();
         } else {
            points.add(stroke[i]!);
         }
       }
       if (points.length > 1) {
          canvas.drawPoints(ui.PointMode.polygon, points, paint);
       }
    }
  }

  @override
  bool shouldRepaint(covariant _ConcealerPainter oldDelegate) {
    return true; 
  }
}
