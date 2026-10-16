import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'frame_selection_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _activePreviewIndex = 0;
  final List<String> _frameAssets = [
    'assets/frame/3.png',
    'assets/frame/1.png',
    'assets/frame/2.png',
  ];

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _showInfoDialog() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'MZ PHOTOBOOTH',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AppColors.primaryBlack,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Aplikasi Photobooth digital portabel dirancang khusus untuk pengalaman berfoto yang estetik, cepat, dan berkesan. Pilih frame kesukaanmu dan abadikan setiap momen penting bersama teman dan orang terdekat.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  height: 1.55,
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified_outlined,
                      size: 18,
                      color: AppColors.primaryBlack,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Versi 1.0 • Mobile Photobooth Experience',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryBlack,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlack,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Tutup',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToFrameSelection() {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const FrameSelectionScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.05),
              end: Offset.zero,
            ).animate(curved),
            child: FadeTransition(opacity: curved, child: child),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 840;

              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 1080 : 540,
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 32 : 20,
                      vertical: isDesktop ? 24 : 14,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Header Section (without stabilo dot)
                        _buildHeader(),
                        SizedBox(height: isDesktop ? 36 : 26),

                        // 2. Hero + Preview Section (side-by-side on desktop, vertical on mobile)
                        if (isDesktop)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Left Column: Hero Text + Primary CTA
                              Expanded(
                                flex: 5,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildHeroText(isDesktop: true),
                                    const SizedBox(height: 32),
                                    _buildPrimaryCTA(),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 48),
                              // Right Column: Featured Photo Preview Card
                              Expanded(
                                flex: 5,
                                child: _buildPreviewCard(),
                              ),
                            ],
                          )
                        else ...[
                          _buildHeroText(isDesktop: false),
                          const SizedBox(height: 22),
                          _buildPreviewCard(),
                        ],
                        SizedBox(height: isDesktop ? 44 : 28),

                        // 3. Preparation & Three-Step Guide (side-by-side on desktop, vertical on mobile)
                        _buildStepSection(isDesktop: isDesktop),
                        SizedBox(height: isDesktop ? 36 : 28),

                        // 4. Primary CTA for mobile (desktop has CTA in hero row)
                        if (!isDesktop) ...[
                          _buildPrimaryCTA(),
                          const SizedBox(height: 20),
                        ],

                        // 5. Subtle Footer
                        _buildFooter(),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left Side: MZ Photobooth Logo + Title (no stabilo dot)
        Expanded(
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.secondaryLime,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondaryLime.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                    const BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Image.asset(
                    'assets/logo/MZP.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.photo_camera_rounded,
                          color: AppColors.primaryBlack,
                          size: 24,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'MZ PHOTOBOOTH',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: AppColors.primaryBlack,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // Right Side: Minimal Information Button
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: _showInfoDialog,
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
                Icons.info_outline_rounded,
                color: AppColors.primaryBlack,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroText({bool isDesktop = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Eyebrow text without stabilo dot
        Text(
          'YOUR PERSONAL PHOTOBOOTH',
          style: GoogleFonts.plusJakartaSans(
            fontSize: isDesktop ? 13 : 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.6,
            color: AppColors.secondaryText,
          ),
        ),
        SizedBox(height: isDesktop ? 16 : 12),

        // Main Heading
        Text(
          'Your moment,\nyour frame.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: isDesktop ? 44 : 34,
            height: 1.12,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            color: AppColors.primaryBlack,
          ),
        ),
        SizedBox(height: isDesktop ? 16 : 12),

        // Indonesian Supporting Text
        Text(
          'Abadikan momenmu, pilih gaya favoritmu, dan simpan hasilnya.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: isDesktop ? 16 : 14.5,
            height: 1.5,
            color: AppColors.secondaryText,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Top Label Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'MZ PHOTOBOOTH LAB',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.3,
                    color: AppColors.primaryBlack,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryLime,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondaryLime.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'CONTOH HASIL',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.primaryBlack,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Frame preview container with real example photo inside frame
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AspectRatio(
              aspectRatio: 1440 / 1380,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Real photo example from assets/example/
                      Positioned.fill(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final w = constraints.maxWidth;
                            final h = constraints.maxHeight;

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
                                    child: Image.asset(
                                      'assets/example/62e6af186f4ee.jpg',
                                      fit: BoxFit.cover,
                                      alignment: const Alignment(0, -0.35),
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey.shade200,
                                          child: const Center(
                                            child: Icon(
                                              Icons.photo_rounded,
                                              color: AppColors.secondaryText,
                                              size: 36,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),

                    // Frame Overlay
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: Image.asset(
                        _frameAssets[_activePreviewIndex],
                        key: ValueKey(_activePreviewIndex),
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

          // Bottom Frame Selector (Centered 01, 02, 03)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(_frameAssets.length, (index) {
                  final isActive = _activePreviewIndex == index;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _activePreviewIndex = index;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      margin: EdgeInsets.only(left: index == 0 ? 0 : 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primaryBlack
                            : AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isActive
                              ? AppColors.primaryBlack
                              : AppColors.border,
                        ),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: AppColors.primaryBlack
                                      .withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        '0${index + 1}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isActive
                              ? AppColors.secondaryLime
                              : AppColors.secondaryText,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepSection({bool isDesktop = false}) {
    final step1 = _buildStepCard(
      stepNumber: '01',
      title: 'Pilih Frame',
      description: 'Tentukan desain favoritmu.',
      icon: Icons.layers_outlined,
      isHighlight: true,
    );
    final step2 = _buildStepCard(
      stepNumber: '02',
      title: 'Ambil Foto',
      description: 'Gunakan kamera depan atau belakang.',
      icon: Icons.camera_alt_outlined,
    );
    final step3 = _buildStepCard(
      stepNumber: '03',
      title: 'Simpan Hasil',
      description: 'Pilih filter dan unduh fotomu.',
      icon: Icons.file_download_outlined,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Text(
          'Siap untuk berfoto?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: isDesktop ? 26 : 22,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
            color: AppColors.primaryBlack,
          ),
        ),
        const SizedBox(height: 5),

        // Supporting Text
        Text(
          'Tiga langkah sederhana untuk hasil yang berkesan.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: isDesktop ? 14.5 : 13.5,
            color: AppColors.secondaryText,
          ),
        ),
        SizedBox(height: isDesktop ? 22 : 18),

        // Three Step Cards (Row on desktop, Column on mobile)
        if (isDesktop)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: step1),
                const SizedBox(width: 14),
                Expanded(child: step2),
                const SizedBox(width: 14),
                Expanded(child: step3),
              ],
            ),
          )
        else
          Column(
            children: [
              step1,
              const SizedBox(height: 10),
              step2,
              const SizedBox(height: 10),
              step3,
            ],
          ),
      ],
    );
  }

  Widget _buildStepCard({
    required String stepNumber,
    required String title,
    required String description,
    required IconData icon,
    bool isHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isHighlight ? AppColors.primaryBlack : AppColors.border,
          width: isHighlight ? 1.5 : 1.0,
        ),
        boxShadow: [
          if (isHighlight)
            BoxShadow(
              color: AppColors.secondaryLime.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 4),
            )
          else
            const BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
        ],
      ),
      child: Row(
        children: [
          // Number badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryBlack,
              shape: BoxShape.circle,
              border: isHighlight
                  ? Border.all(color: AppColors.secondaryLime, width: 2.5)
                  : null,
              boxShadow: isHighlight
                  ? [
                      BoxShadow(
                        color: AppColors.secondaryLime.withValues(alpha: 0.3),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                stepNumber,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: isHighlight
                      ? AppColors.secondaryLime
                      : AppColors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Texts
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlack,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),

          // Icon indicator
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: isHighlight
                  ? AppColors.secondaryLime.withValues(alpha: 0.35)
                  : AppColors.surfaceMuted,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 18,
              color: AppColors.primaryBlack,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryCTA() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlack.withValues(alpha: 0.2),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlack,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18),
        ),
        onPressed: _navigateToFrameSelection,
        child: Row(
          children: [
            // Lime circular icon background
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.secondaryLime,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondaryLime.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt,
                color: AppColors.primaryBlack,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),

            // Button label
            Expanded(
              child: Text(
                'Mulai Sesi Foto',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: AppColors.white,
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Supporting indicator on right (compact and responsive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Mulai',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: AppColors.secondaryLime,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'SIMPLE MOMENTS, BEAUTIFULLY FRAMED.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.8,
            color: AppColors.secondaryText.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }
}
