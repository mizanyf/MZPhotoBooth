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
  // Set of expanded category slotCounts. '1' is expanded by default.
  final Set<String> _expandedSections = {'1'};

  // Currently selected frame
  late Map<String, dynamic> _selectedFrame;

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
      'badge': 'Segera Hadir',
      'isReady': false,
      'icon': Icons.table_rows_rounded,
      'frames': [
        {
          'id': '3-1',
          'title': 'Triple Strip',
          'subtitle': 'Photostrip vertikal 3 pose',
          'asset': '',
          'slots': '3 Foto',
          'isAvailable': false,
        },
        {
          'id': '3-2',
          'title': 'Trio Collage',
          'subtitle': 'Kolase 3 pose ekspresif',
          'asset': '',
          'slots': '3 Foto',
          'isAvailable': false,
        },
        {
          'id': '3-3',
          'title': 'Story Box 3',
          'subtitle': 'Cerita 3 momen bersambung',
          'asset': '',
          'slots': '3 Foto',
          'isAvailable': false,
        },
        {
          'id': '3-4',
          'title': 'Cinema 3-Cut',
          'subtitle': 'Format rol film 3 pose sinematik',
          'asset': '',
          'slots': '3 Foto',
          'isAvailable': false,
        },
      ],
    },
    {
      'slotCount': '4',
      'title': 'Frame 4 Foto',
      'subtitle': 'Format 4-cut photostrip & 2x2 grid viral',
      'badge': 'Segera Hadir',
      'isReady': false,
      'icon': Icons.grid_view_rounded,
      'frames': [
        {
          'id': '4-1',
          'title': 'Korean 4-Cut',
          'subtitle': 'Photostrip 4 pose Korea viral',
          'asset': '',
          'slots': '4 Foto',
          'isAvailable': false,
        },
        {
          'id': '4-2',
          'title': '2x2 Grid Pop',
          'subtitle': 'Grid 4 kotak simetris',
          'asset': '',
          'slots': '4 Foto',
          'isAvailable': false,
        },
        {
          'id': '4-3',
          'title': 'Cinema 4-Strip',
          'subtitle': 'Gaya rol film sinematik',
          'asset': '',
          'slots': '4 Foto',
          'isAvailable': false,
        },
        {
          'id': '4-4',
          'title': 'Quad Collage',
          'subtitle': 'Kolase 4 pose playful kekinian',
          'asset': '',
          'slots': '4 Foto',
          'isAvailable': false,
        },
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    // Default selection is the user-attached Robot frame (first item of Frame 1 Foto)
    _selectedFrame = (_sections[0]['frames'] as List)[0];

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
        _expandedSections.add(slotCount);
      }
    });
  }

  void _onUseFramePressed() {
    final isAvailable = _selectedFrame['isAvailable'] as bool? ?? false;
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
                  'Aset frame ${_selectedFrame['slots']} belum ditambahkan. Silakan pilih dari koleksi 1 Foto!',
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
      'id': _selectedFrame['id'] as String,
      'title': _selectedFrame['title'] as String,
      'subtitle': _selectedFrame['subtitle'] as String,
      'asset': _selectedFrame['asset'] as String,
      'slots': _selectedFrame['slots'] as String,
      'slotCount': (_selectedFrame['slots'] as String).contains('2') ? '2' : '1',
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
    final badge = section['badge'] as String;
    final isReady = section['isReady'] as bool;
    final icon = (section['icon'] as IconData?) ?? Icons.crop_original_rounded;
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
                    // Icon slot count
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
                      child: Icon(
                        icon,
                        size: 20,
                        color: isExpanded
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

                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: isReady
                            ? AppColors.secondaryLime
                            : AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryBlack,
                          letterSpacing: 0.2,
                        ),
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
                                  isReady
                                      ? 'PILIH DESAIN FRAME:'
                                      : 'SLOT FRAME SEGERA HADIR:',
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
                                                    _selectedFrame['id'] ==
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
              aspectRatio: slots == '2 Foto' ? (720 / 1170) : (1440 / 1380),
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
                                Icon(
                                  slots == '2 Foto'
                                      ? Icons.view_agenda_outlined
                                      : (slots == '3 Foto'
                                          ? Icons.table_rows_outlined
                                          : (slots == '4 Foto'
                                              ? Icons.grid_view_rounded
                                              : Icons.crop_original_rounded)),
                                  size: 26,
                                  color: AppColors.secondaryText.withValues(alpha: 0.7),
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

            // Slot Pill Tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.secondaryLime.withValues(alpha: 0.4)
                    : AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                slots,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryBlack,
                ),
              ),
            ),
            const SizedBox(height: 4),

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
    final isAvailable = _selectedFrame['isAvailable'] as bool? ?? false;
    final title = _selectedFrame['title'] as String;
    final slots = _selectedFrame['slots'] as String;

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
                      color: isAvailable ? Colors.green : Colors.orangeAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Pilihan: $title ($slots)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlack,
                    ),
                  ),
                ],
              ),
              if (!isAvailable)
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
                    : Colors.grey.shade400,
                foregroundColor: AppColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              onPressed: _onUseFramePressed,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isAvailable ? AppColors.secondaryLime : Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 15,
                      color: isAvailable ? AppColors.primaryBlack : Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isAvailable ? 'Gunakan Frame Ini' : 'Frame Belum Ditambahkan',
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
