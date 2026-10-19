import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'photo_screen.dart';

class FrameSelectionScreen extends StatefulWidget {
  const FrameSelectionScreen({super.key});

  @override
  State<FrameSelectionScreen> createState() => _FrameSelectionScreenState();
}

class _FrameSelectionScreenState extends State<FrameSelectionScreen>
    with SingleTickerProviderStateMixin {
  // Set of expanded category slotCounts. Empty by default so all categories are collapsed.
  final Set<String> _expandedSections = {};

  // Currently selected frame (null until user selects a frame)
  Map<String, dynamic>? _selectedFrame;

  late final AnimationController _entryController;
  late final Animation<double> _entryAnimation;

  // Frame collections grouped by slot count
  final List<Map<String, dynamic>> _sections = [
    {
      'slotCount': '1',
      'title': 'Frame 1 Foto',
      'subtitle': 'Format single shot klasik photobooth',
      'badge': '3 Desain Aktif',
      'isReady': true,
      'icon': Icons.crop_original_rounded,
      'frames': [
        {
          'id': '1-1',
          'title': 'Robot Signature',
          'subtitle': 'Karakter robot ceria signature "Terima kasih!"',
          'asset': 'assets/frame/frame1foto/3.png',
          'slots': '1 Foto',
          'isAvailable': true,
        },
        {
          'id': '1-2',
          'title': 'Sparkle Lime',
          'subtitle': 'Warna lime signature & bintang "Thanks a Lot!"',
          'asset': 'assets/frame/frame1foto/1.png',
          'slots': '1 Foto',
          'isAvailable': true,
        },
        {
          'id': '1-3',
          'title': 'Clean Studio',
          'subtitle': 'Monokrom studio minimalis & elegan',
          'asset': 'assets/frame/frame1foto/2.png',
          'slots': '1 Foto',
          'isAvailable': true,
        },
      ],
    },
    {
      'slotCount': '2',
      'title': 'Frame 2 Foto',
      'subtitle': 'Format strip 2 pose photostrip vertikal',
      'badge': '3 Desain Aktif',
      'isReady': true,
      'icon': Icons.view_agenda_rounded,
      'frames': [
        {
          'id': '2-1',
          'title': 'Robot Twin Strip',
          'subtitle': 'Strip 2 pose vertikal karakter robot ceria',
          'asset': 'assets/frame/frame2foto/1.png',
          'slots': '2 Foto',
          'isAvailable': true,
        },
        {
          'id': '2-2',
          'title': 'Sparkle Lime Twin',
          'subtitle': 'Warna lime signature & aksen bintang 2 pose',
          'asset': 'assets/frame/frame2foto/2.png',
          'slots': '2 Foto',
          'isAvailable': true,
        },
        {
          'id': '2-3',
          'title': 'Clean Studio Twin',
          'subtitle': 'Strip 2 pose monokrom studio minimalis',
          'asset': 'assets/frame/frame2foto/3.png',
          'slots': '2 Foto',
          'isAvailable': true,
        },
      ],
    },
    {
      'slotCount': '3',
      'title': 'Frame 3 Foto',
      'subtitle': 'Format vertikal 3 pose favorit photostrip',
      'badge': '3 Desain Aktif',
      'isReady': true,
      'icon': Icons.table_rows_rounded,
      'frames': [
        {
          'id': '3-1',
          'title': 'Pink Lily Floral',
          'subtitle': 'Strip 3 pose vertikal aksen bunga lili soft pink',
          'asset': 'assets/frame/frame3foto/1.png',
          'slots': '3 Foto',
          'isAvailable': true,
        },
        {
          'id': '3-2',
          'title': 'Vintage Bow Cream',
          'subtitle': 'Nuansa krem pastel lembut dengan aksen pita vintage',
          'asset': 'assets/frame/frame3foto/2.png',
          'slots': '3 Foto',
          'isAvailable': true,
        },
        {
          'id': '3-3',
          'title': 'Lime Cinema Strip',
          'subtitle': 'Gaya rol film sinematik warna signature lime',
          'asset': 'assets/frame/frame3foto/3.png',
          'slots': '3 Foto',
          'isAvailable': true,
        },
      ],
    },
    {
      'slotCount': '4',
      'title': 'Frame 4 Foto',
      'subtitle': 'Format 2x2 grid viral 4 pose photobooth',
      'badge': '3 Desain Aktif',
      'isReady': true,
      'icon': Icons.grid_view_rounded,
      'frames': [
        {
          'id': '4-1',
          'title': 'Sparkle Lime Grid',
          'subtitle': 'Grid 2x2 simetris warna lime signature ceria',
          'asset': 'assets/frame/frame4foto/1.png',
          'slots': '4 Foto',
          'isAvailable': true,
        },
        {
          'id': '4-2',
          'title': 'Midnight Studio Grid',
          'subtitle': 'Grid 2x2 monokrom hitam studio elegan & aksen lime',
          'asset': 'assets/frame/frame4foto/2.png',
          'slots': '4 Foto',
          'isAvailable': true,
        },
        {
          'id': '4-3',
          'title': 'Clean Studio White',
          'subtitle': 'Grid 2x2 monokrom putih bersih modern & aksen lime',
          'asset': 'assets/frame/frame4foto/3.png',
          'slots': '4 Foto',
          'isAvailable': true,
        },
      ],
    },
  ];

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _entryAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  void _toggleSection(String slotCount) {
    setState(() {
      if (_expandedSections.contains(slotCount)) {
        _expandedSections.remove(slotCount);
      } else {
        _expandedSections
          ..clear()
          ..add(slotCount);
      }
    });
  }

  void _onUseFramePressed() {
    if (_selectedFrame == null) {
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
                  Icons.info_outline_rounded,
                  color: AppColors.primaryBlack,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Silakan pilih salah satu frame terlebih dahulu!',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    final frame = _selectedFrame!;
    final isAvailable = frame['isAvailable'] as bool? ?? false;
    if (!isAvailable) {
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
                  Icons.info_outline_rounded,
                  color: AppColors.primaryBlack,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Aset frame ${frame['slots']} belum ditambahkan. Silakan pilih dari koleksi frame aktif!',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    // Convert to String map for PhotoScreen
    final frameMap = <String, String>{
      'id': frame['id'] as String,
      'title': frame['title'] as String,
      'subtitle': frame['subtitle'] as String,
      'asset': frame['asset'] as String,
      'slots': frame['slots'] as String,
      'slotCount': (frame['slots'] as String).contains('4')
          ? '4'
          : ((frame['slots'] as String).contains('3')
              ? '3'
              : ((frame['slots'] as String).contains('2') ? '2' : '1')),
    };

    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) =>
            PhotoScreen(frame: frameMap),
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
          'Pilih Frame',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryBlack,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _entryAnimation,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880),
              child: Column(
                children: [
                  // Top Guide Hint (replacing the navbar)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryLime,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.touch_app_rounded,
                              size: 16,
                              color: AppColors.primaryBlack,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Ketuk kategori format frame di bawah untuk membuka pilihan frame',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryBlack,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Expandable Category List (Frames 1 Foto, 2 Foto, 3 Foto, 4 Foto)
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _sections.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final section = _sections[index];
                        return _buildSection(section);
                      },
                    ),
                  ),

                  // Bottom Sticky Action Bar
                  _buildBottomActionBar(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(Map<String, dynamic> section) {
    final slotCount = section['slotCount'] as String;
    final title = section['title'] as String;
    final subtitle = section['subtitle'] as String;
    final isReady = section['isReady'] as bool;
    final frames = section['frames'] as List;
    final isExpanded = _expandedSections.contains(slotCount);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExpanded ? AppColors.primaryBlack : AppColors.border,
          width: isExpanded ? 1.6 : 1.0,
        ),
        boxShadow: [
          if (isExpanded)
            BoxShadow(
              color: AppColors.secondaryLime.withValues(alpha: 0.22),
              blurRadius: 14,
              offset: const Offset(0, 4),
            )
          else
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _toggleSection(slotCount),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Tappable: Click to expand / collapse downwards)
                Row(
                  children: [
                    // Outline slot icon with empty center
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: isExpanded
                            ? AppColors.primaryBlack
                            : (isReady
                                ? AppColors.secondaryLime.withValues(alpha: 0.35)
                                : AppColors.surfaceMuted),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: _buildSlotCategoryIcon(
                        slotCount,
                        isExpanded
                            ? AppColors.secondaryLime
                            : AppColors.primaryBlack,
                      ),
                    ),
                    const SizedBox(width: 13),

                    // Title & Subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryBlack,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Animated Chevron (Rotates downwards/upwards)
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isExpanded
                              ? AppColors.primaryBlack
                              : AppColors.surfaceMuted,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: isExpanded
                              ? AppColors.secondaryLime
                              : AppColors.primaryBlack,
                        ),
                      ),
                    ),
                  ],
                ),

                // Expandable Section Content (Expands vertically downwards)
                AnimatedSize(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: isExpanded
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 14),
                            Container(
                              height: 1,
                              color: AppColors.border.withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'PILIH DESAIN FRAME:',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: AppColors.secondaryText,
                                  ),
                                ),
                                Text(
                                  '${frames.length} Desain',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Responsive Vertical Grid: 2 columns on mobile, 4 columns on web
                            LayoutBuilder(
                              builder: (context, constraints) {
                                // Breakpoint: >= 600px web/desktop -> 4 columns; < 600px mobile -> 2 columns
                                final int crossAxisCount =
                                    constraints.maxWidth >= 600 ? 4 : 2;
                                const double spacing = 10.0;

                                final List<List<Map<String, dynamic>>> rows = [];
                                for (int i = 0;
                                    i < frames.length;
                                    i += crossAxisCount) {
                                  final end = (i + crossAxisCount < frames.length)
                                      ? i + crossAxisCount
                                      : frames.length;
                                  rows.add(frames
                                      .sublist(i, end)
                                      .cast<Map<String, dynamic>>());
                                }

                                return Column(
                                  children: List.generate(rows.length, (rowIdx) {
                                    final rowFrames = rows[rowIdx];
                                    final isLastRow = rowIdx == rows.length - 1;

                                    return Padding(
                                      padding: EdgeInsets.only(
                                        bottom: isLastRow ? 0 : spacing,
                                      ),
                                      child: IntrinsicHeight(
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            for (int colIdx = 0;
                                                colIdx < crossAxisCount;
                                                colIdx++) ...[
                                              if (colIdx > 0)
                                                const SizedBox(width: spacing),
                                              if (colIdx < rowFrames.length)
                                                Expanded(
                                                  child: _buildFrameCard(
                                                    rowFrames[colIdx],
                                                    _selectedFrame != null &&
                                                        _selectedFrame!['id'] ==
                                                            rowFrames[colIdx]['id'],
                                                  ),
                                                )
                                              else
                                                const Expanded(
                                                  child: SizedBox.shrink(),
                                                ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                );
                              },
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Custom outline icons with an empty center representing slot count
  Widget _buildSlotCategoryIcon(String slotCount, Color color, {double scale = 1.0}) {
    final digit = slotCount.replaceAll(RegExp(r'[^0-9]'), '');
    Widget iconWidget;

    switch (digit) {
      case '1':
        iconWidget = Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color, width: 2.0),
          ),
        );
        break;
      case '2':
        iconWidget = SizedBox(
          width: 19,
          height: 18,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 19,
                height: 7.5,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: color, width: 1.8),
                ),
              ),
              Container(
                width: 19,
                height: 7.5,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: color, width: 1.8),
                ),
              ),
            ],
          ),
        );
        break;
      case '3':
        iconWidget = SizedBox(
          width: 19,
          height: 20,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (int i = 0; i < 3; i++)
                Container(
                  width: 19,
                  height: 5.0,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(color: color, width: 1.6),
                  ),
                ),
            ],
          ),
        );
        break;
      case '4':
      default:
        iconWidget = SizedBox(
          width: 18.5,
          height: 18.5,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildOutlineSquare(8.0, color),
                  _buildOutlineSquare(8.0, color),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildOutlineSquare(8.0, color),
                  _buildOutlineSquare(8.0, color),
                ],
              ),
            ],
          ),
        );
        break;
    }

    if (scale != 1.0) {
      return Transform.scale(
        scale: scale,
        child: iconWidget,
      );
    }
    return iconWidget;
  }

  Widget _buildOutlineSquare(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(2.5),
        border: Border.all(color: color, width: 1.6),
      ),
    );
  }

  Widget _buildFrameCard(Map<String, dynamic> frame, bool isSelected) {
    final isAvailable = frame['isAvailable'] as bool;
    final title = frame['title'] as String;
    final subtitle = frame['subtitle'] as String;
    final slots = frame['slots'] as String;
    final asset = frame['asset'] as String;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFrame = frame;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlack : AppColors.border,
            width: 1.5,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.secondaryLime.withValues(alpha: 0.4),
                blurRadius: 14,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Frame Preview Thumbnail
            AspectRatio(
              aspectRatio: slots == '4 Foto'
                  ? (1350 / 1170)
                  : (slots == '3 Foto'
                      ? (720 / 1650)
                      : (slots == '2 Foto' ? (720 / 1170) : (1440 / 1380))),
              child: Container(
                decoration: BoxDecoration(
                  color: isAvailable ? AppColors.surfaceMuted : const Color(0xFFF9F9F9),
                  borderRadius: BorderRadius.zero,
                  border: Border.all(
                    color: isAvailable ? AppColors.border : Colors.grey.shade300,
                    style: isAvailable ? BorderStyle.solid : BorderStyle.solid,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: isAvailable
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            color: const Color(0xFFEFEFEF),
                          ),
                          Image.asset(
                            asset,
                            fit: BoxFit.fill,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  size: 28,
                                  color: AppColors.secondaryText,
                                ),
                              );
                            },
                          ),
                          if (isSelected)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryBlack,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: AppColors.secondaryLime,
                                  size: 11,
                                ),
                              ),
                            ),
                        ],
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          // Placeholder preview layout for coming soon slots
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildSlotCategoryIcon(
                                  slots,
                                  AppColors.secondaryText.withValues(alpha: 0.7),
                                  scale: 1.3,
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Slot Siap',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.secondaryText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryBlack,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: AppColors.secondaryLime,
                                  size: 11,
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 8),

            // Frame Title
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryBlack,
              ),
            ),

            // Subtitle
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionBar() {
    final frame = _selectedFrame;
    final bool hasSelection = frame != null;
    final isAvailable = hasSelection && (frame['isAvailable'] as bool? ?? false);
    final title = hasSelection ? (frame['title'] as String) : '';
    final slots = hasSelection ? (frame['slots'] as String) : '';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Selected summary row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: !hasSelection
                          ? AppColors.secondaryText.withValues(alpha: 0.4)
                          : (isAvailable ? Colors.green : Colors.orangeAccent),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    hasSelection
                        ? 'Pilihan: $title ($slots)'
                        : 'Pilih format frame di atas untuk mulai',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: hasSelection
                          ? AppColors.primaryBlack
                          : AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
              if (hasSelection && !isAvailable)
                Text(
                  'Aset belum ada',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade800,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Primary CTA Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isAvailable
                    ? AppColors.primaryBlack
                    : Colors.grey.shade300,
                foregroundColor: isAvailable
                    ? AppColors.white
                    : AppColors.secondaryText,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              onPressed: isAvailable ? _onUseFramePressed : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isAvailable
                          ? AppColors.secondaryLime
                          : Colors.black12,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 15,
                      color: isAvailable
                          ? AppColors.primaryBlack
                          : AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    !hasSelection
                        ? 'Pilih Frame Terlebih Dahulu'
                        : (isAvailable
                            ? 'Gunakan Frame Ini'
                            : 'Frame Belum Ditambahkan'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
