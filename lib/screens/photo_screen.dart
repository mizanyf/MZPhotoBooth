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

  bool _isCameraLoading = false;
  bool _isCaptured = false;
  bool _isCountingDown = false;
  int _countdownNumber = 3;
  bool _showFlash = false;
  bool _isDownloading = false;

  Uint8List? _capturedBytes;
  int _selectedFilterIndex = 0; // 0: Original, 1: Dingin, 2: Hitam Putih

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
  ];

  @override
  void initState() {
    super.initState();
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
    if (_isCountingDown || _isCaptured) return;

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

    // 2. Flash effect
    setState(() {
      _showFlash = true;
      _isCountingDown = false;
      _capturedBytes = captured;
      _isCaptured = true;
    });

    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) {
      setState(() {
        _showFlash = false;
      });
    }
  }

  void _resetSession() {
    setState(() {
      _isCaptured = false;
      _capturedBytes = null;
      _selectedFilterIndex = 0;
      _isCountingDown = false;
      _countdownNumber = 3;
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
    );
  }

  Widget _buildFramedViewfinder() {
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
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: _isCaptured
                            ? Colors.green
                            : (_isCountingDown ? Colors.redAccent : AppColors.primaryBlack),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isCaptured
                          ? 'FOTO TERSIMPAN'
                          : (_isCountingDown ? 'MENGAMBIL FOTO...' : 'STUDIO PHOTOBOOTH'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.3,
                        color: AppColors.primaryBlack,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: _isCaptured ? AppColors.secondaryLime : AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    _isCaptured ? 'SIAP SIMPAN' : 'STANDBY',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                      color: AppColors.primaryBlack,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Viewfinder Frame (Captured inside RepaintBoundary for downloading)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: AspectRatio(
              aspectRatio: 1440 / 1380,
              child: GestureDetector(
                onTap: !_isCaptured && !_isCountingDown ? _startCountdown : null,
                child: RepaintBoundary(
                  key: _previewBoundaryKey,
                  child: Container(
                    color: Colors.transparent,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Layer 1: Photo content inside cutout slot (seamless bleed behind frame)
                        Positioned.fill(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final w = constraints.maxWidth;
                              final h = constraints.maxHeight;

                              // Precise cutout alignment in 1440x1380 space
                              final photoLeft = w * (120.0 / 1440.0);
                              final photoTop = h * (120.0 / 1380.0);
                              final photoWidth = w * (1200.0 / 1440.0);
                              final photoHeight = h * (896.0 / 1380.0);
                              final photoRadius = w * (40.0 / 1440.0);

                              return Stack(
                                children: [
                                  Positioned(
                                    left: photoLeft,
                                    top: photoTop,
                                    width: photoWidth,
                                    height: photoHeight,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(photoRadius),
                                      child: _buildPhotoContent(),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),

                        // Layer 2: Frame Overlay
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
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryBlack.withValues(alpha: 0.85),
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
                                              fontSize: 54,
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.secondaryLime,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        'Bersiap & Tersenyum!',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
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
                  _isCaptured ? Icons.check_circle_outline_rounded : Icons.touch_app_outlined,
                  size: 15,
                  color: AppColors.secondaryText,
                ),
                const SizedBox(width: 6),
                Text(
                  _isCaptured
                      ? 'Foto berhasil dijepret! Pilih filter di bawah.'
                      : 'Ketuk area foto atau tombol di bawah untuk jepret.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: AppColors.secondaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoContent() {
    final filter = _getCurrentColorFilter();

    // 1. Result Mode: Show captured photo from camera with active filter
    if (_isCaptured) {
      Widget imageWidget;
      if (_capturedBytes != null) {
        imageWidget = Image.memory(
          _capturedBytes!,
          fit: BoxFit.cover,
          alignment: Alignment.center,
        );
      } else {
        imageWidget = Container(
          color: const Color(0xFF1A1A1A),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline_rounded, size: 42, color: AppColors.secondaryLime),
                const SizedBox(height: 10),
                Text(
                  'Foto Berhasil Dijepret',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      if (filter != null) {
        return ColorFiltered(
          colorFilter: filter,
          child: imageWidget,
        );
      }
      return imageWidget;
    }

    // 2. Live Capture Mode: Direct live camera stream
    if (_cameraHelper.isInitialized) {
      return HtmlElementView(viewType: _cameraHelper.viewType);
    }

    // Clean Studio Viewfinder Standby (No sample photo!)
    return Container(
      color: const Color(0xFF121212),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isCameraLoading) ...[
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  color: AppColors.secondaryLime,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Mengaktifkan Kamera...',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.videocam_outlined,
                  size: 32,
                  color: AppColors.secondaryLime,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Kamera Langsung Standby',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ketuk tombol jepret untuk mengambil foto',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCaptureControls() {
    return Column(
      children: [
        const SizedBox(height: 8),

        // Shutter Button
        GestureDetector(
          onTap: !_isCountingDown ? _startCountdown : null,
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
                'Ambil Foto (3 Detik)',
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
              Text(
                _filters[_selectedFilterIndex]['name'],
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryBlack,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Filter cards (Original, Dingin, Hitam Putih)
        Row(
          children: List.generate(_filters.length, (index) {
            final filter = _filters[index];
            final isSelected = _selectedFilterIndex == index;

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedFilterIndex = index;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(
                    left: index == 0 ? 0 : 5,
                    right: index == _filters.length - 1 ? 0 : 5,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.primaryBlack : AppColors.border,
                      width: isSelected ? 2.0 : 1.0,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: AppColors.secondaryLime.withValues(alpha: 0.4),
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
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
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
                      const SizedBox(height: 8),
                      Text(
                        filter['name'],
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryBlack,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        filter['subtitle'],
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
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
