import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../utils/camera_helper.dart';
import '../utils/file_saver.dart';

class PhotoScreen extends StatefulWidget {
  final Map<String, String> frame;

  const PhotoScreen({
    super.key,
    required this.frame,
  });

  @override
  State<PhotoScreen> createState() => _PhotoScreenState();
}

class _PhotoScreenState extends State<PhotoScreen> with TickerProviderStateMixin {
  final GlobalKey _previewBoundaryKey = GlobalKey();
  final WebCameraHelper _cameraHelper = WebCameraHelper();

  int get _slotCount =>
      widget.frame['slotCount'] == '2' || widget.frame['slots']?.contains('2') == true ? 2 : 1;

  bool _isCameraLoading = false;
  bool _isCaptured = false;
  bool _isCountingDown = false;
  bool _isWaitingNextPose = false;
  int _countdownNumber = 3;
  bool _showFlash = false;
  bool _isDownloading = false;

  int _activeCaptureSlot = 0;
  late List<Uint8List?> _capturedPhotos;
  int _selectedFilterIndex = 0;
  int _cameraKey = 0;

  Timer? _countdownTimer;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

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
        0.00, 0.94, 0.00, 0.0,  0.0,
        0.00, 0.00, 1.25, 0.0, 18.0,
        0.00, 0.00, 0.00, 1.0,  0.0,
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
        1.12,  0.05, -0.05, 0.0, 12.0,
       -0.02,  1.05,  0.02, 0.0,  6.0,
       -0.08,  0.04,  0.88, 0.0, 22.0,
        0.00,  0.00,  0.00, 1.0,  0.0,
      ],
    },
    {
      'id': 'retro',
      'name': 'Retro',
      'subtitle': 'Nostalgia 80s',
      'icon': Icons.filter_vintage_outlined,
      'matrix': const <double>[
        1.18,  0.08, -0.04, 0.0, 16.0,
        0.06,  0.98,  0.02, 0.0, 10.0,
       -0.12,  0.04,  0.76, 0.0, 14.0,
        0.00,  0.00,  0.00, 1.0,  0.0,
      ],
    },
    {
      'id': 'soft',
      'name': 'Soft',
      'subtitle': 'Pastel Glow',
      'icon': Icons.face_retouching_natural_rounded,
      'matrix': const <double>[
        0.96,  0.06,  0.04, 0.0, 22.0,
        0.03,  0.95,  0.04, 0.0, 18.0,
        0.04,  0.04,  0.96, 0.0, 20.0,
        0.00,  0.00,  0.00, 1.0,  0.0,
      ],
    },
    {
      'id': 'cyberpunk',
      'name': 'Cyberpunk',
      'subtitle': 'Neon Night',
      'icon': Icons.electric_bolt_rounded,
      'matrix': const <double>[
        1.35, -0.10,  0.05, 0.0, 15.0,
       -0.10,  1.15,  0.10, 0.0, -5.0,
        0.10,  0.05,  1.45, 0.0, 20.0,
        0.00,  0.00,  0.00, 1.0,  0.0,
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _capturedPhotos = List.filled(_slotCount, null);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOutBack),
    );
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
    _pulseController.dispose();
    _cameraHelper.dispose();
    super.dispose();
  }

  void _startCountdown() {
    if (_isCountingDown || _isCaptured || _isWaitingNextPose) return;

    setState(() {
      _isCountingDown = true;
      _countdownNumber = 3;
    });

    _pulseController.forward(from: 0.0);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_countdownNumber > 1) {
        setState(() {
          _countdownNumber--;
        });
        _pulseController.forward(from: 0.0);
      } else {
        timer.cancel();
        _triggerShutterCapture();
      }
    });
  }

  Future<void> _triggerShutterCapture() async {
    // 1. Trigger snapshot from webcam if active
    Uint8List? captured;
    if (_cameraHelper.isInitialized) {
      captured = _cameraHelper.captureFrame();
    }

    // 2. Flash effect & store in current active slot
    setState(() {
      _showFlash = true;
      _isCountingDown = false;
      _capturedPhotos[_activeCaptureSlot] = captured;
    });

    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    setState(() {
      _showFlash = false;
    });

    // 3. Multi-slot progression
    if (_activeCaptureSlot + 1 < _slotCount) {
      setState(() {
        _activeCaptureSlot++;
        _isWaitingNextPose = true;
      });

      // Brief breather so users can switch pose (1.8s)
      await Future.delayed(const Duration(milliseconds: 1800));
      if (!mounted) return;

      setState(() {
        _isWaitingNextPose = false;
      });

      // Automatically start countdown for next pose
      _startCountdown();
    } else {
      // All poses captured!
      setState(() {
        _isCaptured = true;
      });
    }
  }

  void _resetSession() {
    setState(() {
      _isCaptured = false;
      _activeCaptureSlot = 0;
      _capturedPhotos = List.filled(_slotCount, null);
      _selectedFilterIndex = 0;
      _isCountingDown = false;
      _isWaitingNextPose = false;
      _countdownNumber = 3;
      _cameraKey++;
    });

    _cameraHelper.resumeCamera();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && !_isCaptured) {
        _cameraHelper.resumeCamera();
      }
    });
  }

  Future<void> _downloadFramedPhoto() async {
    if (_isDownloading) return;

    setState(() => _isDownloading = true);

    try {
      // Find boundary render object
      final boundary = _previewBoundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;

      if (boundary == null) {
        throw Exception('Render boundary tidak ditemukan');
      }

      // Convert to image with high resolution 3.0 ratio
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

  @override
  Widget build(BuildContext context) {
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
          _isCaptured ? 'Hasil Foto' : 'Sesi Foto',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryBlack,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  widget.frame['title']!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlack,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: _slotCount == 2 ? 420 : 560,
              ),
              child: Column(
                children: [
                  // 1. Camera / Photo Viewfinder with Frame Overlay
                  _buildFramedViewfinder(),
                  const SizedBox(height: 16),

                  // 2. Mode controls depending on state
                  if (!_isCaptured) ...[
                    // Camera source selector & shutter button
                    _buildCaptureControls(),
                  ] else ...[
                    // Filter selector & result action buttons
                    _buildResultControls(),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFramedViewfinder() {
    final double frameAspectRatio =
        _slotCount == 2 ? (720.0 / 1170.0) : (1440.0 / 1380.0);

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
          // Top subtle indicator bar
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isCaptured) ...[
                      const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      _isCaptured
                          ? (_slotCount > 1
                              ? '2 POSE TERSIMPAN • SELESAI'
                              : 'FOTO TERSIMPAN • SELESAI')
                          : (_isCountingDown
                              ? 'MENGAMBIL POSE ${_activeCaptureSlot + 1} DARI $_slotCount...'
                              : (_isWaitingNextPose
                                  ? 'GANTI POSE BERIKUTNYA...'
                                  : 'STUDIO PHOTOBOOTH • $_slotCount POSE')),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: AppColors.primaryBlack,
                      ),
                    ),
                  ],
                ),
                Text(
                  _isCaptured
                      ? 'LENGKAP'
                      : (_isCountingDown
                          ? 'COUNTDOWN'
                          : (_isWaitingNextPose ? 'GANTI POSE' : 'STANDBY')),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: _isCountingDown
                        ? Colors.orangeAccent.shade700
                        : AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),

          // Main Viewfinder Frame (Captured inside RepaintBoundary for downloading)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: AspectRatio(
              aspectRatio: frameAspectRatio,
              child: GestureDetector(
                onTap: !_isCaptured && !_isCountingDown && !_isWaitingNextPose
                    ? _startCountdown
                    : null,
                child: RepaintBoundary(
                  key: _previewBoundaryKey,
                  child: Container(
                    color: Colors.transparent,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Layer 1: Photo content inside cutout slots (seamless bleed behind frame)
                        Positioned.fill(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final w = constraints.maxWidth;
                              final h = constraints.maxHeight;

                              if (_slotCount == 2) {
                                // Slot 1: Top cut (64, 64, 592, 441 in 720x1170 space)
                                final s1Left = w * (64.0 / 720.0);
                                final s1Top = h * (64.0 / 1170.0);
                                final s1Width = w * (592.0 / 720.0);
                                final s1Height = h * (441.0 / 1170.0);

                                // Slot 2: Bottom cut (64, 544, 592, 441 in 720x1170 space)
                                final s2Left = w * (64.0 / 720.0);
                                final s2Top = h * (544.0 / 1170.0);
                                final s2Width = w * (592.0 / 720.0);
                                final s2Height = h * (441.0 / 1170.0);

                                return Stack(
                                  children: [
                                    Positioned(
                                      left: s1Left,
                                      top: s1Top,
                                      width: s1Width,
                                      height: s1Height,
                                      child: ClipRect(
                                        child: _buildSlotContent(0),
                                      ),
                                    ),
                                    Positioned(
                                      left: s2Left,
                                      top: s2Top,
                                      width: s2Width,
                                      height: s2Height,
                                      child: ClipRect(
                                        child: _buildSlotContent(1),
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
                                        child: _buildSlotContent(0),
                                      ),
                                    ),
                                  ],
                                );
                              }
                            },
                          ),
                        ),

                        // Layer 2: Frame Overlay (transparent cutouts reveal photo underneath)
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

                        // Layer 3: Countdown Overlay (3, 2, 1)
                        if (_isCountingDown)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.45),
                              child: Center(
                                child: ScaleTransition(
                                  scale: _pulseAnimation,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 90,
                                        height: 90,
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryBlack
                                              .withValues(alpha: 0.85),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppColors.secondaryLime,
                                            width: 4,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.secondaryLime
                                                  .withValues(alpha: 0.5),
                                              blurRadius: 24,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            '$_countdownNumber',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 50,
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.secondaryLime,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryBlack
                                              .withValues(alpha: 0.75),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          _slotCount > 1
                                              ? 'Pose ${_activeCaptureSlot + 1} dari $_slotCount: Bersiap!'
                                              : 'Bersiap & Tersenyum!',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Layer 3b: Pose transition breather overlay
                        if (_isWaitingNextPose)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.55),
                              child: Center(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 24),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 18, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlack,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: AppColors.secondaryLime,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.secondaryLime
                                            .withValues(alpha: 0.35),
                                        blurRadius: 20,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
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
                                      Flexible(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Pose 1 Tersimpan!',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13.5,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Ganti gayamu untuk Pose 2...',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                color: AppColors.secondaryLime,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
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
                          ),

                        // Layer 4: Shutter Flash Animation
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

          // Bottom card helper text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isCaptured
                      ? Icons.check_circle_outline_rounded
                      : Icons.touch_app_outlined,
                  size: 15,
                  color: AppColors.secondaryText,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _isCaptured
                        ? (_slotCount > 1
                            ? 'Kedua pose berhasil dijepret! Pilih filter di bawah.'
                            : 'Foto berhasil dijepret! Pilih filter di bawah.')
                        : (_isWaitingNextPose
                            ? 'Pose 1 siap! Menyiapkan pose ke-2...'
                            : (_isCountingDown
                                ? 'Tersenyum ke kamera... 3, 2, 1!'
                                : (_slotCount > 1
                                    ? 'Ketuk tombol di bawah untuk jepret 2 pose beruntun.'
                                    : 'Ketuk area foto atau tombol di bawah untuk jepret.'))),
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

  Widget _buildSlotContent(int slotIndex) {
    final filter = _getCurrentColorFilter();
    final photoBytes =
        slotIndex < _capturedPhotos.length ? _capturedPhotos[slotIndex] : null;

    // 1. Result / Frozen Mode: Display captured photo for this slot
    if (photoBytes != null) {
      Widget imageWidget = Image.memory(
        photoBytes,
        fit: BoxFit.cover,
        alignment: Alignment.center,
      );

      if (filter != null) {
        return ColorFiltered(
          colorFilter: filter,
          child: imageWidget,
        );
      }
      return imageWidget;
    }

    // 2. If session ended but no photo bytes (fallback)
    if (_isCaptured) {
      return Container(
        color: const Color(0xFF1A1A1A),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                size: 36,
                color: AppColors.secondaryLime,
              ),
              const SizedBox(height: 8),
              Text(
                'Pose ${slotIndex + 1} Berhasil',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 3. Live Capture Mode: Is this slot currently active?
    if (slotIndex == _activeCaptureSlot) {
      if (_cameraHelper.isInitialized) {
        return HtmlElementView(
          key: ValueKey('live-camera-$_cameraKey-$slotIndex'),
          viewType: _cameraHelper.viewType,
          onPlatformViewCreated: (_) {
            _cameraHelper.resumeCamera();
          },
        );
      }

      // Standby / Loading state for active slot
      return Container(
        color: const Color(0xFF121212),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isCameraLoading) ...[
                const SizedBox(
                  width: 30,
                  height: 30,
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
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.videocam_outlined,
                    size: 28,
                    color: AppColors.secondaryLime,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _slotCount > 1
                      ? 'Kamera Standby (Pose ${slotIndex + 1})'
                      : 'Kamera Langsung Standby',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ketuk tombol jepret untuk mulai',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 10.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // 4. Inactive slot waiting for turn (e.g. Pose 2 while Pose 1 is in progress)
    return Container(
      color: const Color(0xFF1E1E1E),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.hourglass_empty_rounded,
                size: 22,
                color: AppColors.secondaryLime,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pose ${slotIndex + 1}',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Menunggu giliran...',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptureControls() {
    String buttonText;
    if (_slotCount == 1) {
      buttonText = 'Ambil Foto (3 Detik)';
    } else {
      if (_activeCaptureSlot == 0) {
        buttonText = 'Mulai Sesi (Pose 1 & 2)';
      } else {
        buttonText = 'Ambil Pose 2';
      }
    }

    return Column(
      children: [
        // Multi-pose step indicators
        if (_slotCount > 1) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPoseStepPill(0, 'Pose 1'),
              const SizedBox(width: 8),
              _buildPoseStepPill(1, 'Pose 2'),
            ],
          ),
          const SizedBox(height: 14),
        ],

        // Shutter Button
        GestureDetector(
          onTap: !_isCountingDown && !_isWaitingNextPose
              ? _startCountdown
              : null,
          child: Column(
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
              const SizedBox(height: 10),
              Text(
                buttonText,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryBlack,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPoseStepPill(int index, String label) {
    final bool isDone = _capturedPhotos[index] != null;
    final bool isActive = _activeCaptureSlot == index && !isDone;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDone
            ? AppColors.secondaryLime
            : (isActive ? AppColors.primaryBlack : AppColors.surfaceMuted),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive || isDone
              ? AppColors.primaryBlack
              : AppColors.border,
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDone
                ? Icons.check_circle_rounded
                : (isActive ? Icons.camera_alt_rounded : Icons.circle_outlined),
            size: 13,
            color: isDone
                ? AppColors.primaryBlack
                : (isActive ? AppColors.secondaryLime : AppColors.secondaryText),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDone
                  ? AppColors.primaryBlack
                  : (isActive ? AppColors.white : AppColors.secondaryText),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildResultControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Filter Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PILIH FILTER',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AppColors.secondaryText,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.secondaryLime.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _filters[_selectedFilterIndex]['name'],
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlack,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Filter cards (Original, Dingin, Hitam Putih, Analog, Retro, Soft, Cyberpunk)
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
                            color:
                                AppColors.secondaryLime.withValues(alpha: 0.45),
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
        const SizedBox(height: 22),

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

        // 3. Ulangi Sesi Foto Button (Secondary Action)
        SizedBox(
          width: double.infinity,
          height: 52,
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
            onPressed: _resetSession,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.replay_rounded,
                  size: 18,
                  color: AppColors.primaryBlack,
                ),
                const SizedBox(width: 8),
                Text(
                  'Ulangi Sesi Foto',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
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
