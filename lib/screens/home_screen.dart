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
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
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
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 24,
                offset: Offset(0, -4),
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
                'MZ PHOTOBOOTH STUDIO',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
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
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 840;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // 1. Top Hero Banner (Curved bottom, sleek dark background, circular logo, title, and lime CTA)
                  _buildHeroBanner(context, isDesktop),

                  // 2. Three Steps Section ("Tiga langkah saja")
                  _buildStepsSection(isDesktop),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context, bool isDesktop) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF101115),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(36),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle ambient lime accent glow in the background
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondaryLime.withValues(alpha: 0.06),
              ),
            ),
          ),

          // Info button in top right
          Positioned(
            top: topPadding + 12,
            right: 18,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _showInfoDialog,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),

          // Banner Content
          Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              topPadding + 28,
              24,
              isDesktop ? 44 : 36,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 580),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Circular Logo Badge (lime background, zero white, smooth circle, no square)
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.secondaryLime.withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/logo/MZP.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.photo_camera_rounded,
                                color: AppColors.primaryBlack,
                                size: 28,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Big Bold Headline: PHOTOBOOTH STUDIO
                    Text(
                      'PHOTOBOOTH STUDIO',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isDesktop ? 32 : 25,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Description text (Starts with "Pilih bingkai terlebih dahulu")
                    Text(
                      'Pilih bingkai terlebih dahulu, ambil pose terbaikmu di depan kamera, lalu simpan hasilnya secara instan ke perangkatmu.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isDesktop ? 14 : 13,
                        height: 1.55,
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 26),

                    // Pill CTA Button (Hijau Stabilo)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondaryLime,
                        foregroundColor: AppColors.primaryBlack,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                        shadowColor: AppColors.secondaryLime,
                      ),
                      onPressed: _navigateToFrameSelection,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.photo_camera_rounded,
                            size: 19,
                            color: AppColors.primaryBlack,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'MULAI SEKARANG',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                              color: AppColors.primaryBlack,
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
        ],
      ),
    );
  }

  Widget _buildStepsSection(bool isDesktop) {
    final step1 = _buildStepCard(
      number: '1',
      icon: Icons.tune_rounded,
      title: 'Atur dulu',
      description: 'Pilih orientasi & layout frame 1, 2, 3, atau 4 foto sesuai konsep gayamu.',
    );
    final step2 = _buildStepCard(
      number: '2',
      icon: Icons.photo_camera_rounded,
      title: 'Ambil Pose',
      description: 'Posisikan webcam, pasang senyum terbaik, dan jepret dengan hitungan mundur otomatis.',
    );
    final step3 = _buildStepCard(
      number: '3',
      icon: Icons.auto_awesome_rounded,
      title: 'Simpan Hasil',
      description: 'Pilih filter warna estetik favoritmu dan unduh hasil photostrip langsung secara instan.',
    );

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isDesktop ? 880 : 520),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          child: Column(
            children: [
              // Section Title: "Tiga langkah saja"
              Text(
                'Tiga langkah saja',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryBlack,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 20),

              // Responsive Cards: Row on Desktop, Column on Mobile
              if (isDesktop)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: step1),
                      const SizedBox(width: 16),
                      Expanded(child: step2),
                      const SizedBox(width: 16),
                      Expanded(child: step3),
                    ],
                  ),
                )
              else
                Column(
                  children: [
                    step1,
                    const SizedBox(height: 14),
                    step2,
                    const SizedBox(height: 14),
                    step3,
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepCard({
    required String number,
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _navigateToFrameSelection,
        borderRadius: BorderRadius.circular(24),
        hoverColor: AppColors.secondaryLime.withValues(alpha: 0.1),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              // Top row with step number badge on top-left
              Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryBlack,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        number,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 4),

              // Center circular icon
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.6),
                  ),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 28,
                    color: AppColors.primaryBlack,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryBlack,
                ),
              ),
              const SizedBox(height: 6),

              // Description
              Text(
                description,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  height: 1.45,
                  color: AppColors.secondaryText,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
