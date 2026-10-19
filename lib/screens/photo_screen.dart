// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../utils/camera_helper.dart';
import '../utils/file_saver.dart';

enum SessionMode {
  capture, // Live clean camera viewfinder (no frame)
  reviewPose, // Reviewing a single photo after capture (for multi-pose frames)
  finalResult, // Viewing framed result with photos inside the frame
}

class PhotoScreen extends StatefulWidget {
  final Map<String, String> frame;

  const PhotoScreen({
    super.key,
    required this.frame,
  });

  @override
  State<PhotoScreen> createState() => _PhotoScreenState();
}

class _PhotoScreenState extends State<PhotoScreen> {
  final GlobalKey _previewBoundaryKey = GlobalKey();
  final WebCameraHelper _cameraHelper = WebCameraHelper();

  int get _slotCount {
    final s = widget.frame['slotCount'] ?? widget.frame['slots'] ?? '1';
    if (s.contains('4')) return 4;
    if (s.contains('3')) return 3;
    if (s.contains('2')) return 2;
    return 1;
  }

  SessionMode _sessionMode = SessionMode.capture;
  int _activeCaptureSlot = 0; // 0 or 1 (which slot we are capturing)
  int _reviewingSlotIndex = 0; // 0 or 1 (which slot we are reviewing)
  late List<Uint8List?> _capturedPhotos;

  bool _isCameraLoading = false;
  bool _isSwitchingCamera = false;
  bool _isCountingDown = false;
  int _countdownNumber = 3;
  bool _showFlash = false;
  bool _isDownloading = false;

  int _selectedFilterIndex = 0;
  Timer? _countdownTimer;

  final List<Map<String, dynamic>> _filters = [
    {
      'id': 'original',
      'name': 'Original',
      'subtitle': 'Warna Alami',
      'icon': Icons.wb_sunny_outlined,
      'matrix': null,
    },
    {
      'id': 'cool',
      'name': 'Dingin',
      'subtitle': 'Tone Sejuk',
      'icon': Icons.ac_unit_rounded,
      'matrix': const <double>[
        0.88, 0.00, 0.00, 0.0, -8.0,
        0.00, 0.94, 0.00, 0.0, 0.0,
        0.00, 0.00, 1.25, 0.0, 18.0,
        0.00, 0.00, 0.00, 1.0, 0.0,
      ],
    },
    {
      'id': 'bw',
      'name': 'Hitam Putih',
      'subtitle': 'Klasik Studio',
      'icon': Icons.contrast_rounded,
      'matrix': const <double>[
        0.299, 0.587, 0.114, 0.0, 0.0,
        0.299, 0.587, 0.114, 0.0, 0.0,
        0.299, 0.587, 0.114, 0.0, 0.0,
        0.000, 0.000, 0.000, 1.0, 0.0,
      ],
    },
    {
      'id': 'analog',
      'name': 'Analog',
      'subtitle': 'Film 35mm',
      'icon': Icons.camera_roll_outlined,
      'matrix': const <double>[
        1.12, 0.05, -0.05, 0.0, 12.0,
        -0.02, 1.05, 0.02, 0.0, 6.0,
        -0.08, 0.04, 0.88, 0.0, 22.0,
        0.00, 0.00, 0.00, 1.0, 0.0,
      ],
    },
    {
      'id': 'retro',
      'name': 'Retro',
      'subtitle': 'Nostalgia 80s',
      'icon': Icons.filter_vintage_outlined,
      'matrix': const <double>[
        1.18, 0.08, -0.04, 0.0, 16.0,
        0.06, 0.98, 0.02, 0.0, 10.0,
        -0.12, 0.04, 0.76, 0.0, 14.0,
        0.00, 0.00, 0.00, 1.0, 0.0,
      ],
    },
    {
      'id': 'soft',
      'name': 'Soft',
      'subtitle': 'Pastel Glow',
      'icon': Icons.face_retouching_natural_rounded,
      'matrix': const <double>[
        0.96, 0.06, 0.04, 0.0, 22.0,
        0.03, 0.95, 0.04, 0.0, 18.0,
        0.04, 0.04, 0.96, 0.0, 20.0,
        0.00, 0.00, 0.00, 1.0, 0.0,
      ],
    },
    {
      'id': 'cyberpunk',
      'name': 'Cyberpunk',
      'subtitle': 'Neon Night',
      'icon': Icons.electric_bolt_rounded,
      'matrix': const <double>[
        1.35, -0.10, 0.05, 0.0, 15.0,
        -0.10, 1.15, 0.10, 0.0, -5.0,
        0.10, 0.05, 1.45, 0.0, 20.0,
        0.00, 0.00, 0.00, 1.0, 0.0,
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _capturedPhotos = List.filled(_slotCount, null);
    _initCamera();
  }

  Future<void> _initCamera() async {
    setState(() => _isCameraLoading = true);
    await _cameraHelper.startCamera();
    if (mounted) {
      setState(() {
        _isCameraLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _cameraHelper.dispose();
    super.dispose();
  }

  void _startCountdown() {
    if (_isCountingDown || _isCameraLoading) return;

    setState(() {
      _isCountingDown = true;
      _countdownNumber = 3;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_countdownNumber > 1) {
        setState(() {
          _countdownNumber--;
        });
      } else {
        timer.cancel();
        _triggerShutterCapture();
      }
    });
  }

  Future<void> _triggerShutterCapture() async {
    // 1. Capture frame from webcam
    Uint8List? captured;
    if (_cameraHelper.isInitialized) {
      captured = _cameraHelper.captureFrame();
    }

    // Fallback if camera stream didn't provide bytes (e.g. testing environment)
    captured ??= await _generateFallbackPhoto(_activeCaptureSlot);

    // 2. Flash effect & store in current active slot
    setState(() {
      _showFlash = true;
      _isCountingDown = false;
      _capturedPhotos[_activeCaptureSlot] = captured;
    });

    await Future.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;

    setState(() {
      _showFlash = false;
    });

    // 3. Navigation according to slot count
    if (_slotCount == 1) {
      // 1-photo frame: directly show result with frame!
      setState(() {
        _sessionMode = SessionMode.finalResult;
      });
    } else {
      // Multi-photo frame: review the photo that was just taken
      setState(() {
        _sessionMode = SessionMode.reviewPose;
        _reviewingSlotIndex = _activeCaptureSlot;
      });
    }
  }

  Future<Uint8List> _generateFallbackPhoto(int slotIndex) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 592, 441));
    final bgPaint = Paint()..color = const Color(0xFF1E1E24);
    canvas.drawRect(const Rect.fromLTWH(0, 0, 592, 441), bgPaint);

    final borderPaint = Paint()
      ..color = AppColors.secondaryLime.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRect(const Rect.fromLTWH(12, 12, 568, 417), borderPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: '📸 Pose ${slotIndex + 1}\nPhotobooth Shot',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.bold,
          height: 1.3,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: 500);
    textPainter.paint(
      canvas,
      Offset(296 - textPainter.width / 2, 220 - textPainter.height / 2),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(592, 441);
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    return bd!.buffer.asUint8List();
  }

  // --- Actions in Review Mode ---
  void _retakePose(int slotIndex) {
    _countdownTimer?.cancel();
    setState(() {
      _capturedPhotos[slotIndex] = null;
      _activeCaptureSlot = slotIndex;
      _sessionMode = SessionMode.capture;
      _isCountingDown = false;
    });
    _cameraHelper.resumeCamera();
  }

  void _retakeCurrentReviewPose() {
    _retakePose(_reviewingSlotIndex);
  }

  void _proceedFromReviewPose() {
    final bool allPhotosReady = _slotCount > 1 &&
        _capturedPhotos.length >= _slotCount &&
        _capturedPhotos.every((p) => p != null);

    if (allPhotosReady) {
      setState(() {
        _sessionMode = SessionMode.finalResult;
      });
      return;
    }

    final int nextEmptySlot = _capturedPhotos.indexWhere((p) => p == null);
    if (nextEmptySlot != -1) {
      setState(() {
        _activeCaptureSlot = nextEmptySlot;
        _sessionMode = SessionMode.capture;
        _isCountingDown = false;
      });
      _cameraHelper.resumeCamera();
    } else {
      setState(() {
        _sessionMode = SessionMode.finalResult;
      });
    }
  }

  // --- Actions in Final Result Mode ---

  void _resetEntireSession() {
    setState(() {
      _sessionMode = SessionMode.capture;
      _activeCaptureSlot = 0;
      _reviewingSlotIndex = 0;
      _capturedPhotos = List.filled(_slotCount, null);
      _selectedFilterIndex = 0;
      _isCountingDown = false;
      _countdownNumber = 3;
    });
    _cameraHelper.resumeCamera();
  }

  Future<void> _downloadFramedPhoto() async {
    if (_isDownloading) return;

    setState(() => _isDownloading = true);

    try {
      final boundary = _previewBoundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;

      if (boundary == null) {
        throw Exception('Render boundary tidak ditemukan');
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Gagal membuat data gambar');
      }

      final pngBytes = byteData.buffer.asUint8List();
      final fileName =
          'mzphotobooth_${widget.frame['id']}_${DateTime.now().millisecondsSinceEpoch}.png';

      FileSaver.saveFile(pngBytes, fileName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primaryBlack,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.secondaryLime,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: AppColors.primaryBlack,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Foto berhasil diunduh ke perangkatmu!',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            content: Text(
              'Gagal mengunduh foto: $e',
              style: GoogleFonts.plusJakartaSans(color: Colors.white),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  ColorFilter? _getCurrentColorFilter() {
    final matrix = _filters[_selectedFilterIndex]['matrix'] as List<double>?;
    if (matrix == null) return null;
    return ColorFilter.matrix(matrix);
  }

  String get _appBarTitle {
    switch (_sessionMode) {
      case SessionMode.capture:
        return _slotCount > 1
            ? 'Ambil Foto ${_activeCaptureSlot + 1} dari $_slotCount'
            : 'Ambil Foto';
      case SessionMode.reviewPose:
        return 'Review Foto ${_reviewingSlotIndex + 1}';
      case SessionMode.finalResult:
        return 'Hasil Foto Frame';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Width constraint: 2-photo & 3-photo vertical strip is compact (420), capture & 1-photo/4-photo frame is wide (540)
    final double maxContentWidth =
        _sessionMode == SessionMode.finalResult &&
                (_slotCount == 2 || _slotCount == 3)
            ? 420
            : 540;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.primaryBlack,
                    size: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
        title: Text(
          _appBarTitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryBlack,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: true,
        // Removed frame name widget from the top right corner as requested
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: Column(
                children: [
                  // 1. Photobooth Journey Stepper Bar
                  _buildJourneyStepper(),
                  const SizedBox(height: 14),

                  // 2. Camera Viewfinder (Kept persistent in tree with Offstage so webcam never unmounts or gets stuck)
                  Offstage(
                    offstage: _sessionMode != SessionMode.capture,
                    child: Column(
                      children: [
                        _buildCleanCameraViewfinder(),
                        const SizedBox(height: 16),
                        _buildCaptureControls(),
                      ],
                    ),
                  ),

                  // 3. Review Pose View (shown only during reviewPose)
                  if (_sessionMode == SessionMode.reviewPose) ...[
                    _buildReviewPoseView(),
                    const SizedBox(height: 16),
                    _buildReviewPoseControls(),
                  ],

                  // 4. Final Framed Result (shown only during finalResult)
                  if (_sessionMode == SessionMode.finalResult) ...[
                    _buildFramedResultView(),
                    const SizedBox(height: 16),
                    _buildFinalResultControls(),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // STEPPER PROGRESS BAR
  // --------------------------------------------------------------------------
  Widget _buildJourneyStepper() {
    final bool isCaptureOrReview =
        _sessionMode == SessionMode.capture || _sessionMode == SessionMode.reviewPose;
    final bool isFinalResult = _sessionMode == SessionMode.finalResult;

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStepItem(
              stepNumber: '1',
              title: 'Foto Kamera',
              isActive: isCaptureOrReview,
              isCompleted: isFinalResult,
            ),
            Container(
              width: 32,
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: isFinalResult ? AppColors.primaryBlack : AppColors.border,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            _buildStepItem(
              stepNumber: '2',
              title: 'Hasil Frame',
              isActive: isFinalResult,
              isCompleted: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem({
    required String stepNumber,
    required String title,
    required bool isActive,
    required bool isCompleted,
  }) {
    Color bg;
    Color textColor;
    if (isCompleted) {
      bg = AppColors.secondaryLime;
      textColor = AppColors.primaryBlack;
    } else if (isActive) {
      bg = AppColors.primaryBlack;
      textColor = Colors.white;
    } else {
      bg = AppColors.surfaceMuted;
      textColor = AppColors.secondaryText;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive || isCompleted
                  ? AppColors.primaryBlack
                  : AppColors.border,
              width: 1.2,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 13, color: AppColors.primaryBlack)
                : Text(
                    stepNumber,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: isActive || isCompleted ? FontWeight.w700 : FontWeight.w500,
            color: isActive || isCompleted
                ? AppColors.primaryBlack
                : AppColors.secondaryText,
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // 1. CLEAN CAMERA VIEWFINDER (NO FRAME)
  // --------------------------------------------------------------------------
  Widget _buildCleanCameraViewfinder() {
    const double cameraAspectRatio = 592.0 / 441.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header Bar inside card (No dot, text split left & right)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _slotCount > 1 ? 'KAMERA LIVE' : 'KAMERA LIVE PHOTOBOOTH',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: AppColors.primaryBlack,
                  ),
                ),
                if (_slotCount > 1)
                  Text(
                    'POSE ${_activeCaptureSlot + 1} DARI $_slotCount',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: AppColors.primaryBlack,
                    ),
                  ),
              ],
            ),
          ),

          // Camera Viewport (Clean, full view without frame)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: AspectRatio(
              aspectRatio: cameraAspectRatio,
              child: GestureDetector(
                onTap: !_isCountingDown ? _startCountdown : null,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    color: const Color(0xFF0F0F12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Layer 1: Live Webcam Stream (Persistent Platform View)
                        if (_cameraHelper.isInitialized)
                          HtmlElementView(
                            key: const ValueKey('live-camera-persistent-view'),
                            viewType: _cameraHelper.viewType,
                            onPlatformViewCreated: (_) {
                              _cameraHelper.resumeCamera();
                            },
                          )
                        else
                          _buildCameraLoadingOrError(),

                        // Layer 2: Viewfinder Camera HUD Guides (No "foto bersih" pill)
                        _buildViewfinderHUD(),

                        // Layer 3: Countdown Number Only (Clean & Unobtrusive, No circle, No pop-up, No dark curtain)
                        if (_isCountingDown)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Center(
                                child: Text(
                                  '$_countdownNumber',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 68,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.secondaryLime,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withValues(alpha: 0.75),
                                        offset: const Offset(0, 4),
                                        blurRadius: 18,
                                      ),
                                      Shadow(
                                        color: Colors.black.withValues(alpha: 0.9),
                                        offset: const Offset(0, 1),
                                        blurRadius: 5,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Layer 4: Shutter Flash
                        if (_showFlash)
                          Positioned.fill(
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 150),
                              opacity: _showFlash ? 1.0 : 0.0,
                              child: Container(color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom helper message
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.touch_app_outlined,
                  size: 15,
                  color: AppColors.secondaryText,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _isCountingDown
                        ? 'Tersenyum ke arah kamera... 3, 2, 1!'
                        : (_slotCount > 1
                            ? 'Posisikan dirimu untuk Pose ${_activeCaptureSlot + 1} dari $_slotCount, lalu ketuk tombol jepret.'
                            : 'Posisikan dirimu di tengah frame, lalu ketuk tombol jepret.'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: AppColors.secondaryText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraLoadingOrError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isCameraLoading) ...[
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                color: AppColors.secondaryLime,
                strokeWidth: 2.8,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Mengaktifkan Kamera...',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.videocam_outlined,
                size: 30,
                color: AppColors.secondaryLime,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Kamera Standby',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ketuk tombol jepret untuk mulai',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildViewfinderHUD() {
    return Stack(
      children: [
        // Framing Corner Brackets [ ]
        Positioned(
          left: 14,
          top: 14,
          child: _buildCornerBracket(isTop: true, isLeft: true),
        ),
        Positioned(
          right: 14,
          top: 14,
          child: _buildCornerBracket(isTop: true, isLeft: false),
        ),
        Positioned(
          left: 14,
          bottom: 14,
          child: _buildCornerBracket(isTop: false, isLeft: true),
        ),
        Positioned(
          right: 14,
          bottom: 14,
          child: _buildCornerBracket(isTop: false, isLeft: false),
        ),

        // Subtle Center Crosshair
        Center(
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.secondaryLime.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCornerBracket({required bool isTop, required bool isLeft}) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? const BorderSide(color: AppColors.secondaryLime, width: 2.2)
              : BorderSide.none,
          bottom: !isTop
              ? const BorderSide(color: AppColors.secondaryLime, width: 2.2)
              : BorderSide.none,
          left: isLeft
              ? const BorderSide(color: AppColors.secondaryLime, width: 2.2)
              : BorderSide.none,
          right: !isLeft
              ? const BorderSide(color: AppColors.secondaryLime, width: 2.2)
              : BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildCaptureControls() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Tombol Galeri (Kiri)
              _buildSideControlButton(
                icon: Icons.photo_library_outlined,
                label: 'Galeri',
                onTap: !_isCountingDown ? _pickImageFromGallery : null,
              ),

              // 2. Tombol Ambil Foto Utama (Tengah)
              GestureDetector(
                onTap: !_isCountingDown ? _startCountdown : null,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 78,
                      height: 78,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.white,
                        border: Border.all(color: AppColors.primaryBlack, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryBlack.withValues(alpha: 0.15),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: AppColors.primaryBlack,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: AppColors.secondaryLime,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: AppColors.primaryBlack,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ambil Foto',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryBlack,
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Tombol Balik Kamera (Kanan)
              _buildSideControlButton(
                icon: Icons.flip_camera_ios_rounded,
                label: 'Balik Kamera',
                onTap: (!_isCountingDown && !_isSwitchingCamera)
                    ? _switchCamera
                    : null,
                isLoading: _isSwitchingCamera,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSideControlButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    bool isLoading = false,
  }) {
    final bool isEnabled = onTap != null;

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.45,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryBlack,
                        ),
                      )
                    : Icon(
                        icon,
                        size: 21,
                        color: AppColors.primaryBlack,
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _switchCamera() async {
    if (_isSwitchingCamera || _isCountingDown) return;
    setState(() => _isSwitchingCamera = true);

    await _cameraHelper.switchCamera();

    if (mounted) {
      setState(() => _isSwitchingCamera = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1400),
          backgroundColor: AppColors.primaryBlack,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Row(
            children: [
              Icon(
                _cameraHelper.isFrontCamera
                    ? Icons.camera_front_rounded
                    : Icons.camera_rear_rounded,
                color: AppColors.secondaryLime,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(
                _cameraHelper.isFrontCamera
                    ? 'Beralih ke Kamera Depan'
                    : 'Beralih ke Kamera Belakang',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _pickImageFromGallery() {
    if (!kIsWeb) return;
    try {
      final uploadInput = html.FileUploadInputElement()..accept = 'image/*';
      uploadInput.click();
      uploadInput.onChange.listen((e) {
        final files = uploadInput.files;
        if (files != null && files.isNotEmpty) {
          final reader = html.FileReader();
          reader.readAsArrayBuffer(files[0]);
          reader.onLoadEnd.listen((e) async {
            if (reader.result == null) return;
            final bytes = Uint8List.fromList(reader.result as List<int>);
            if (!mounted) return;

            final croppedBytes = await showDialog<Uint8List>(
              context: context,
              barrierDismissible: false,
              builder: (context) => _CropPhotoDialog(
                imageBytes: bytes,
                slotIndex: _activeCaptureSlot,
              ),
            );

            if (croppedBytes != null && mounted) {
              setState(() {
                _capturedPhotos[_activeCaptureSlot] = croppedBytes;
              });

              if (_slotCount == 1) {
                setState(() {
                  _sessionMode = SessionMode.finalResult;
                });
              } else {
                setState(() {
                  _sessionMode = SessionMode.reviewPose;
                  _reviewingSlotIndex = _activeCaptureSlot;
                });
              }
            }
          });
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Gagal memilih foto: $e'),
          ),
        );
      }
    }
  }

  // --------------------------------------------------------------------------
  // 2. REVIEW SINGLE POSE VIEW (For Multi-Pose / 2-Photo Frame)
  // --------------------------------------------------------------------------
  Widget _buildReviewPoseView() {
    const double photoAspectRatio = 592.0 / 441.0;
    final photoBytes = _capturedPhotos[_reviewingSlotIndex];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header Bar (No "berhasil diambil" badge)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 15,
                  color: Colors.green,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'REVIEW FOTO ${_reviewingSlotIndex + 1} DARI $_slotCount',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: AppColors.primaryBlack,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Captured Photo Display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: AspectRatio(
              aspectRatio: photoAspectRatio,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  color: const Color(0xFF161618),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (photoBytes != null)
                        Image.memory(
                          photoBytes,
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                        )
                      else
                        const Center(
                          child: Icon(Icons.broken_image_outlined,
                              color: Colors.white, size: 40),
                        ),

                      // Overlay chip: Foto #
                      Positioned(
                        bottom: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlack.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.secondaryLime,
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.photo_camera_rounded,
                                size: 12,
                                color: AppColors.secondaryLime,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Foto ${_reviewingSlotIndex + 1}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Review instruction card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: AppColors.primaryBlack,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _reviewingSlotIndex < _slotCount - 1
                            ? 'Pose ${_reviewingSlotIndex + 1} Sudah Sesuai?'
                            : 'Semua Foto Berhasil Diambil!',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryBlack,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _reviewingSlotIndex < _slotCount - 1
                            ? 'Kamu bisa ulangi jika kurang pas, atau lanjut mengambil foto berikutnya.'
                            : 'Semua fotomu siap digabung ke dalam frame.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDualPoseBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          for (int i = 0; i < _slotCount; i++) ...[
            if (i > 0)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: _slotCount >= 4 ? 1 : (_slotCount >= 3 ? 2 : 4),
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: _slotCount >= 4 ? 10 : (_slotCount >= 3 ? 12 : 16),
                  color: AppColors.secondaryText,
                ),
              ),
            Expanded(
              child: _buildPoseRetakeChip(
                slotIndex: i,
                label: 'Pose ${i + 1}',
                photoBytes: i < _capturedPhotos.length ? _capturedPhotos[i] : null,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPoseRetakeChip({
    required int slotIndex,
    required String label,
    required Uint8List? photoBytes,
  }) {
    final bool isExtraCompact = _slotCount >= 4;
    final bool isCompact = _slotCount >= 3;
    final double thumbW = isExtraCompact ? 26 : (isCompact ? 34 : 44);
    final double thumbH = isExtraCompact ? 20 : (isCompact ? 26 : 32);
    final double btnSize = isExtraCompact ? 18 : (isCompact ? 24 : 28);
    final double iconSize = isExtraCompact ? 11 : (isCompact ? 14 : 17);

    return Tooltip(
      message: 'Take ulang $label',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _retakePose(slotIndex),
          borderRadius: BorderRadius.circular(10),
          hoverColor: AppColors.secondaryLime.withValues(alpha: 0.15),
          splashColor: AppColors.secondaryLime.withValues(alpha: 0.25),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isExtraCompact ? 1 : (isCompact ? 2 : 4),
              vertical: 3,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nomor di sebelah kiri foto dengan tutup kurung sebagai pemisah
                  Padding(
                    padding: EdgeInsets.only(
                      left: 1,
                      right: isExtraCompact ? 2 : (isCompact ? 3 : 6),
                    ),
                    child: Text(
                      '${slotIndex + 1})',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isExtraCompact ? 10 : (isCompact ? 11 : 12.5),
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryBlack,
                      ),
                    ),
                  ),
                  // Thumb foto
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      width: thumbW,
                      height: thumbH,
                      child: photoBytes != null
                          ? Image.memory(photoBytes, fit: BoxFit.cover)
                          : Container(
                              color: AppColors.surfaceMuted,
                              child: Icon(
                                Icons.camera_alt_outlined,
                                size: isExtraCompact ? 12 : 15,
                                color: AppColors.secondaryText,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(width: isExtraCompact ? 3 : (isCompact ? 4 : 6)),
                  // Logo take ulang foto (lingkaran tunjuk)
                  Container(
                    width: btnSize,
                    height: btnSize,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.border,
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.replay_rounded,
                      size: iconSize,
                      color: AppColors.primaryBlack,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewPoseControls() {
    final bool allPhotosReady = _slotCount > 1 &&
        _capturedPhotos.length >= _slotCount &&
        _capturedPhotos.every((p) => p != null);
    final bool showDualBar = _slotCount > 1 && (allPhotosReady || _reviewingSlotIndex > 0);
    final int nextEmpty = _capturedPhotos.indexWhere((p) => p == null);

    return Column(
      children: [
        // Mini preview of both photos with retake button (replaces old checkmark pill)
        if (showDualBar) ...[
          _buildDualPoseBar(),
          const SizedBox(height: 12),
        ],

        // Primary Continue Button
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlack,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: _proceedFromReviewPose,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: AppColors.secondaryLime,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    allPhotosReady
                        ? Icons.auto_awesome_rounded
                        : Icons.arrow_forward_rounded,
                    size: 15,
                    color: AppColors.primaryBlack,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  allPhotosReady
                      ? 'Lihat Hasil dengan Frame'
                      : (nextEmpty != -1
                          ? 'Lanjut Foto ${nextEmpty + 1}'
                          : 'Lihat Hasil dengan Frame'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Secondary Retake Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.white,
              foregroundColor: AppColors.primaryBlack,
              side: const BorderSide(color: AppColors.border, width: 1.5),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: _retakeCurrentReviewPose,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.replay_rounded,
                  size: 17,
                  color: AppColors.primaryBlack,
                ),
                const SizedBox(width: 8),
                Text(
                  'Ulangi Foto ${_reviewingSlotIndex + 1}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlack,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // 3. FINAL FRAMED RESULT VIEW (Combined With Frame)
  // --------------------------------------------------------------------------
  Widget _buildFramedResultView() {
    final double frameAspectRatio = _slotCount == 4
        ? (1350.0 / 1170.0)
        : (_slotCount == 3
            ? (720.0 / 1650.0)
            : (_slotCount == 2 ? (720.0 / 1170.0) : (1440.0 / 1380.0)));

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Top Header Bar (Centered Brand Label)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
            child: Center(
              child: Text(
                'MZ Photobooth',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AppColors.primaryBlack,
                ),
              ),
            ),
          ),

          // Main Framed Result inside RepaintBoundary (for saving PNG)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: AspectRatio(
              aspectRatio: frameAspectRatio,
              child: RepaintBoundary(
                key: _previewBoundaryKey,
                child: Container(
                  color: Colors.transparent,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Layer 1: Photos inside cutouts (seamless bleed under frame borders)
                      Positioned.fill(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final w = constraints.maxWidth;
                            final h = constraints.maxHeight;

                            if (_slotCount == 4) {
                              // Slot 1: Top-Left (64, 64, 592, 442 in 1350x1170 space, 2px bleed)
                              final s1Left = w * (62.0 / 1350.0);
                              final s1Top = h * (62.0 / 1170.0);
                              final s1Width = w * (596.0 / 1350.0);
                              final s1Height = h * (446.0 / 1170.0);

                              // Slot 2: Top-Right (694, 64, 592, 442 in 1350x1170 space, 2px bleed)
                              final s2Left = w * (692.0 / 1350.0);
                              final s2Top = h * (62.0 / 1170.0);
                              final s2Width = w * (596.0 / 1350.0);
                              final s2Height = h * (446.0 / 1170.0);

                              // Slot 3: Bottom-Left (64, 544, 592, 442 in 1350x1170 space, 2px bleed)
                              final s3Left = w * (62.0 / 1350.0);
                              final s3Top = h * (542.0 / 1170.0);
                              final s3Width = w * (596.0 / 1350.0);
                              final s3Height = h * (446.0 / 1170.0);

                              // Slot 4: Bottom-Right (694, 544, 592, 442 in 1350x1170 space, 2px bleed)
                              final s4Left = w * (692.0 / 1350.0);
                              final s4Top = h * (542.0 / 1170.0);
                              final s4Width = w * (596.0 / 1350.0);
                              final s4Height = h * (446.0 / 1170.0);

                              return Stack(
                                children: [
                                  Positioned(
                                    left: s1Left,
                                    top: s1Top,
                                    width: s1Width,
                                    height: s1Height,
                                    child: ClipRect(
                                      child: _buildFramedSlotPhoto(0),
                                    ),
                                  ),
                                  Positioned(
                                    left: s2Left,
                                    top: s2Top,
                                    width: s2Width,
                                    height: s2Height,
                                    child: ClipRect(
                                      child: _buildFramedSlotPhoto(1),
                                    ),
                                  ),
                                  Positioned(
                                    left: s3Left,
                                    top: s3Top,
                                    width: s3Width,
                                    height: s3Height,
                                    child: ClipRect(
                                      child: _buildFramedSlotPhoto(2),
                                    ),
                                  ),
                                  Positioned(
                                    left: s4Left,
                                    top: s4Top,
                                    width: s4Width,
                                    height: s4Height,
                                    child: ClipRect(
                                      child: _buildFramedSlotPhoto(3),
                                    ),
                                  ),
                                ],
                              );
                            } else if (_slotCount == 3) {
                              // Slot 1: Top cut (64, 64, 592, 441 in 720x1650 space, 2px bleed)
                              final s1Left = w * (62.0 / 720.0);
                              final s1Top = h * (62.0 / 1650.0);
                              final s1Width = w * (596.0 / 720.0);
                              final s1Height = h * (445.0 / 1650.0);

                              // Slot 2: Middle cut (64, 544, 592, 441 in 720x1650 space, 2px bleed)
                              final s2Left = w * (62.0 / 720.0);
                              final s2Top = h * (542.0 / 1650.0);
                              final s2Width = w * (596.0 / 720.0);
                              final s2Height = h * (445.0 / 1650.0);

                              // Slot 3: Bottom cut (64, 1024, 592, 441 in 720x1650 space, 2px bleed)
                              final s3Left = w * (62.0 / 720.0);
                              final s3Top = h * (1022.0 / 1650.0);
                              final s3Width = w * (596.0 / 720.0);
                              final s3Height = h * (445.0 / 1650.0);

                              return Stack(
                                children: [
                                  Positioned(
                                    left: s1Left,
                                    top: s1Top,
                                    width: s1Width,
                                    height: s1Height,
                                    child: ClipRect(
                                      child: _buildFramedSlotPhoto(0),
                                    ),
                                  ),
                                  Positioned(
                                    left: s2Left,
                                    top: s2Top,
                                    width: s2Width,
                                    height: s2Height,
                                    child: ClipRect(
                                      child: _buildFramedSlotPhoto(1),
                                    ),
                                  ),
                                  Positioned(
                                    left: s3Left,
                                    top: s3Top,
                                    width: s3Width,
                                    height: s3Height,
                                    child: ClipRect(
                                      child: _buildFramedSlotPhoto(2),
                                    ),
                                  ),
                                ],
                              );
                            } else if (_slotCount == 2) {
                              // Slot 1: Top cut (60, 60, 600, 449 in 720x1170 space)
                              final s1Left = w * (60.0 / 720.0);
                              final s1Top = h * (60.0 / 1170.0);
                              final s1Width = w * (600.0 / 720.0);
                              final s1Height = h * (449.0 / 1170.0);

                              // Slot 2: Bottom cut (60, 540, 600, 449 in 720x1170 space)
                              final s2Left = w * (60.0 / 720.0);
                              final s2Top = h * (540.0 / 1170.0);
                              final s2Width = w * (600.0 / 720.0);
                              final s2Height = h * (449.0 / 1170.0);

                              return Stack(
                                children: [
                                  Positioned(
                                    left: s1Left,
                                    top: s1Top,
                                    width: s1Width,
                                    height: s1Height,
                                    child: ClipRect(
                                      child: _buildFramedSlotPhoto(0),
                                    ),
                                  ),
                                  Positioned(
                                    left: s2Left,
                                    top: s2Top,
                                    width: s2Width,
                                    height: s2Height,
                                    child: ClipRect(
                                      child: _buildFramedSlotPhoto(1),
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              // 1-photo single cutout in 1440x1380 space
                              final photoLeft = w * (120.0 / 1440.0);
                              final photoTop = h * (120.0 / 1380.0);
                              final photoWidth = w * (1200.0 / 1440.0);
                              final photoHeight = h * (896.0 / 1380.0);

                              return Stack(
                                children: [
                                  Positioned(
                                    left: photoLeft,
                                    top: photoTop,
                                    width: photoWidth,
                                    height: photoHeight,
                                    child: ClipRect(
                                      child: _buildFramedSlotPhoto(0),
                                    ),
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                      ),

                      // Layer 2: Frame Asset Overlay (transparent cutouts show photos)
                      Positioned.fill(
                        child: Image.asset(
                          widget.frame['asset']!,
                          fit: BoxFit.fill,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.image_outlined,
                                size: 48,
                                color: AppColors.secondaryText,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom card tip
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.palette_outlined,
                  size: 15,
                  color: AppColors.secondaryText,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _slotCount > 1
                        ? '${_slotCount == 4 ? "Keempat" : (_slotCount == 3 ? "Ketiga" : "Kedua")} foto berhasil disatukan! Pilih filter & unduh fotomu.'
                        : 'Foto berhasil dipasang! Pilih filter & unduh fotomu.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: AppColors.secondaryText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFramedSlotPhoto(int slotIndex) {
    final photoBytes =
        slotIndex < _capturedPhotos.length ? _capturedPhotos[slotIndex] : null;
    final filter = _getCurrentColorFilter();

    if (photoBytes != null) {
      Widget image = Image.memory(
        photoBytes,
        fit: BoxFit.cover,
        alignment: Alignment.center,
      );

      if (filter != null) {
        return ColorFiltered(
          colorFilter: filter,
          child: image,
        );
      }
      return image;
    }

    return Container(
      color: const Color(0xFF1E1E1E),
      child: Center(
        child: Text(
          'Pose ${slotIndex + 1}',
          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildFinalResultControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Filter Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'PILIH FILTER',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: AppColors.secondaryText,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Filter list carousel
        SizedBox(
          height: 112,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                ui.PointerDeviceKind.touch,
                ui.PointerDeviceKind.mouse,
                ui.PointerDeviceKind.trackpad,
              },
            ),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              itemCount: _filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _selectedFilterIndex == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedFilterIndex = index;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    width: 94,
                    padding: const EdgeInsets.symmetric(
                      vertical: 9,
                      horizontal: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryBlack
                            : AppColors.border,
                        width: isSelected ? 2.0 : 1.0,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: AppColors.secondaryLime
                                .withValues(alpha: 0.45),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          )
                        else
                          const BoxShadow(
                            color: AppColors.cardShadow,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryBlack
                                : AppColors.surfaceMuted,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            filter['icon'] as IconData,
                            size: 18,
                            color: isSelected
                                ? AppColors.secondaryLime
                                : AppColors.primaryBlack,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          filter['name'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryBlack,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          filter['subtitle'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 20),

        // 2. Download Button (Primary CTA)
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlack,
              foregroundColor: AppColors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            onPressed: _isDownloading ? null : _downloadFramedPhoto,
            child: _isDownloading
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: AppColors.secondaryLime,
                          strokeWidth: 2.5,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Menyiapkan Foto...'),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.secondaryLime,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.download_rounded,
                          size: 16,
                          color: AppColors.primaryBlack,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Download Foto',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 10),

        // 3. Multi-slot individual retake bar with thumbnails and retake buttons (if > 1 photos)
        if (_slotCount > 1) ...[
          _buildDualPoseBar(),
          const SizedBox(height: 10),
        ],

        // 4. Ulangi Foto / Sesi Baru Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.white,
              foregroundColor: AppColors.primaryBlack,
              side: const BorderSide(color: AppColors.border, width: 1.5),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: _resetEntireSession,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.refresh_rounded,
                  size: 18,
                  color: AppColors.primaryBlack,
                ),
                const SizedBox(width: 8),
                Text(
                  _slotCount > 1 ? 'Ulangi Sesi Baru ($_slotCount Foto)' : 'Ulangi Foto',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlack,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------------------
// INTERACTIVE CROP PHOTO DIALOG
// ----------------------------------------------------------------------------
class _CropPhotoDialog extends StatefulWidget {
  final Uint8List imageBytes;
  final int slotIndex;

  const _CropPhotoDialog({
    required this.imageBytes,
    required this.slotIndex,
  });

  @override
  State<_CropPhotoDialog> createState() => _CropPhotoDialogState();
}

class _CropPhotoDialogState extends State<_CropPhotoDialog> {
  final GlobalKey _cropBoundaryKey = GlobalKey();
  final TransformationController _transController = TransformationController();
  bool _isProcessing = false;

  void _resetTransform() {
    setState(() {
      _transController.value = Matrix4.identity();
    });
  }

  Future<void> _applyCrop() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      await Future.delayed(const Duration(milliseconds: 60));
      final boundary = _cropBoundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Render boundary tidak ditemukan');
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 2.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Gagal memproses gambar');
      }

      final croppedBytes = byteData.buffer.asUint8List();
      if (mounted) {
        Navigator.of(context).pop(croppedBytes);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Gagal memotong foto: $e'),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _transController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryLime,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.crop_rounded,
                              size: 16,
                              color: AppColors.primaryBlack,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sesuaikan Foto (Pose ${widget.slotIndex + 1})',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryBlack,
                                ),
                              ),
                              Text(
                                'Geser dan atur posisi foto agar pas',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: AppColors.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        color: AppColors.secondaryText,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, color: AppColors.border),

                // Crop Viewport Container (Aspect ratio 592/441)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: AspectRatio(
                    aspectRatio: 592.0 / 441.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F0F12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primaryBlack,
                          width: 2,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // 1. RepaintBoundary captured area
                          RepaintBoundary(
                            key: _cropBoundaryKey,
                            child: Container(
                              color: const Color(0xFF0F0F12),
                              child: ClipRect(
                                child: InteractiveViewer(
                                  transformationController: _transController,
                                  clipBehavior: Clip.none,
                                  minScale: 0.5,
                                  maxScale: 4.0,
                                  boundaryMargin:
                                      const EdgeInsets.all(double.infinity),
                                  child: Image.memory(
                                    widget.imageBytes,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // 2. Guide Overlay (Grid lines & subtle border)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppColors.secondaryLime
                                        .withValues(alpha: 0.8),
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Container(
                                      height: 1,
                                      color:
                                          Colors.white.withValues(alpha: 0.2),
                                    ),
                                    Container(
                                      height: 1,
                                      color:
                                          Colors.white.withValues(alpha: 0.2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Container(
                                    width: 1,
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                  Container(
                                    width: 1,
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Helper tip (Cubit ratakan kiri, Geser ratakan kanan dengan icon sendiri, tanda bulat dihilangkan)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.pinch_outlined,
                            size: 14,
                            color: AppColors.secondaryText,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Cubit/scroll untuk zoom',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppColors.secondaryText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.pan_tool_alt_outlined,
                            size: 14,
                            color: AppColors.secondaryText,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Geser untuk reposisi',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppColors.secondaryText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Action Buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      // Reset Button
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryBlack,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                        onPressed: _resetTransform,
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: Text(
                          'Reset',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Confirm & Crop Button
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlack,
                            foregroundColor: AppColors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 13,
                            ),
                          ),
                          onPressed: _isProcessing ? null : _applyCrop,
                          icon: _isProcessing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.secondaryLime,
                                  ),
                                )
                              : const Icon(
                                  Icons.check_rounded,
                                  size: 17,
                                  color: AppColors.secondaryLime,
                                ),
                          label: Text(
                            _isProcessing ? 'Memproses...' : 'Gunakan Foto Ini',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
