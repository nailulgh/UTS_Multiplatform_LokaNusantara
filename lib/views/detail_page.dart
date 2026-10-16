import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:intl/intl.dart';
import '../models/destination_model.dart';
import '../models/itinerary_note_model.dart';
import '../services/persistence_service.dart';

class DetailPage extends StatefulWidget {
  const DetailPage({super.key});

  static const String routeName = '/detail';

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  static const Color primaryTeal = Color(0xFF0D9488);
  static const Color primaryDark = Color(0xFF0F766E);
  static const Color primaryLight = Color(0xFFCCFBF1);
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color tertiaryTerracotta = Color(0xFFC36D4B);
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color borderSubtle = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color favoriteRed = Color(0xFFEF4444);

  bool _isFavorite = false;
  bool _isInit = false;
  int _selectedGalleryIndex = 0;

  ItineraryNoteModel? _destinationNote;
  bool _isNoteLoading = true;
  String _localFilePath = PersistenceService.localNotesFileName;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final item =
          ModalRoute.of(context)?.settings.arguments as DestinationModel?;
      if (item != null) {
        _isFavorite = item.isFavorite;
        _loadPersistenceDataForItem(item.id);
      }
      _isInit = true;
    }
  }

  /// Memuat status favorit dari SharedPreferences dan catatan kunjungan dari File lokal secara asinkron.
  Future<void> _loadPersistenceDataForItem(String destinationId) async {
    final ItineraryNoteModel? savedNote =
        await PersistenceService.readNoteForDestination(destinationId);
    final String filePath = await PersistenceService.getLocalNotesFilePath();

    if (!mounted) return;
    setState(() {
      _destinationNote = savedNote;
      _localFilePath = filePath;
      _isNoteLoading = false;
    });
  }

  /// Mengubah status favorit dan menyimpannya secara persisten ke SharedPreferences.
  Future<void> _toggleFavorite(DestinationModel item) async {
    final bool newStatus = await PersistenceService.toggleFavoriteId(item.id);
    if (!mounted) return;

    setState(() {
      _isFavorite = newStatus;
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _isFavorite
                    ? '${item.name} disimpan ke SharedPreferences! ❤️'
                    : '${item.name} dihapus dari SharedPreferences.',
              ),
            ),
          ],
        ),
        backgroundColor: _isFavorite ? primaryTeal : textPrimary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Menampilkan dialog untuk menulis atau memperbarui catatan rencana kunjungan ke File lokal.
  void _showNoteEditorDialog(DestinationModel item) {
    final TextEditingController dateCtrl = TextEditingController(
      text: _destinationNote?.plannedDate ?? '25 Oktober 2026',
    );
    final TextEditingController noteCtrl = TextEditingController(
      text: _destinationNote?.noteText ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.edit_note_rounded, color: primaryTeal),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _destinationNote == null
                    ? 'Tulis Catatan Kunjungan'
                    : 'Edit Catatan Kunjungan',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Destinasi: ${item.name}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: primaryDark,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dateCtrl,
                decoration: InputDecoration(
                  labelText: 'Rencana Tanggal Kunjungan',
                  hintText: 'Contoh: 25 Oktober 2026',
                  prefixIcon: const Icon(Icons.calendar_today, size: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Catatan Rencana / Barang Bawaan / Ulasan',
                  hintText:
                      'Tulis catatan perjalanan, estimasi budget, atau kuliner yang ingin dicoba...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final String plannedDate = dateCtrl.text.trim();
              final String noteText = noteCtrl.text.trim();
              if (noteText.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Isi catatan tidak boleh kosong.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              final String timestamp =
                  DateFormat("dd MMM yyyy, HH:mm 'WIB'").format(DateTime.now());
              final ItineraryNoteModel newNote = ItineraryNoteModel(
                destinationId: item.id,
                destinationName: item.name,
                plannedDate:
                    plannedDate.isEmpty ? 'Belum ditentukan' : plannedDate,
                noteText: noteText,
                updatedAt: timestamp,
              );

              Navigator.pop(ctx);
              await PersistenceService.writeNoteToFile(newNote);
              if (!mounted) return;
              setState(() {
                _destinationNote = newNote;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Catatan berhasil ditulis ke file catatan_wisata_lokanusantara.json!',
                  ),
                  backgroundColor: primaryTeal,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryTeal),
            icon: const Icon(Icons.save_outlined, size: 16, color: Colors.white),
            label: const Text(
              'Simpan ke File',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// Menghapus catatan rencana kunjungan dari File lokal.
  Future<void> _deleteLocalNote(DestinationModel item) async {
    await PersistenceService.deleteNoteFromFile(item.id);
    if (!mounted) return;
    setState(() {
      _destinationNote = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Catatan dihapus dari file catatan_wisata_lokanusantara.json.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item =
        ModalRoute.of(context)?.settings.arguments as DestinationModel?;

    if (item == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Destinasi')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.info_outline, size: 48, color: textMuted),
              const SizedBox(height: 12),
              const Text('Data destinasi tidak ditemukan.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kembali ke Beranda'),
              ),
            ],
          ),
        ),
      );
    }

    final List<String> activeGallery =
        item.gallery.isNotEmpty ? item.gallery : [item.imageUrl];

    return Scaffold(
      backgroundColor: backgroundLight,
      body: Stack(
        children: [
          // 1. KONTEN UTAMA YANG DAPAT DIGULIR (SCROLLABLE)
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroBanner(item, activeGallery),
                Transform.translate(
                  offset: const Offset(0, -24),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: surfaceWhite,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 24.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Kategori & Label Harga Utama
                        _buildCategoryAndPriceRow(item),

                        const SizedBox(height: 12),

                        // Nama Destinasi / Judul Utama
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                            letterSpacing: -0.3,
                            height: 1.3,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Lokasi Jalan / Wilayah Lengkap
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 16,
                              color: primaryTeal,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                item.address,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: textMuted,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        _buildQuickStatBadges(item),

                        const SizedBox(height: 24),

                        if (activeGallery.length > 1) ...[
                          _buildGalleryThumbnails(activeGallery),
                          const SizedBox(height: 24),
                        ],

                        // Tentang Destinasi
                        const Text(
                          'Tentang Destinasi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.description,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.65,
                            color: textMuted,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Fasilitas & Layanan Unggulan
                        if (item.facilities.isNotEmpty) ...[
                          _buildFacilitiesSection(item),
                          const SizedBox(height: 24),
                        ],

                        // Seksi Catatan Rencana Kunjungan (Read & Write Files Persistence)
                        _buildLocalFileNoteSection(item),

                        const SizedBox(height: 24),

                        _buildGpsMapCard(item),

                        const SizedBox(height: 90),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. FLOATING TOP APP BAR (BACK & BOOKMARK)
          _buildFloatingTopBar(item),

          // 3. FIXED BOTTOM ACTION BAR (CTA PETUNJUK ARAH)
          _buildBottomActionBar(item),
        ],
      ),
    );
  }

  /// Komponen UI untuk menampilkan dan mengelola Catatan Rencana Kunjungan
  /// menggunakan teknik Read and Write Files (catatan_wisata_lokanusantara.json).
  Widget _buildLocalFileNoteSection(DestinationModel item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentAmber.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentAmber.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.folder_special_rounded,
                      color: Color(0xFFB45309),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Catatan Rencana Kunjungan',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        'Read & Write File (catatan_wisata_lokanusantara.json)',
                        style: TextStyle(fontSize: 10.5, color: textMuted),
                      ),
                    ],
                  ),
                ],
              ),
              if (_destinationNote != null)
                IconButton(
                  onPressed: () => _deleteLocalNote(item),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: favoriteRed,
                    size: 20,
                  ),
                  tooltip: 'Hapus Catatan dari File',
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isNoteLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_destinationNote == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: surfaceWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderSubtle),
              ),
              child: const Text(
                'Belum ada catatan rencana kunjungan pada penyimpanan file lokal untuk destinasi ini.',
                style: TextStyle(fontSize: 12.5, color: textMuted, height: 1.4),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: surfaceWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.event_available_rounded,
                        size: 14,
                        color: primaryTeal,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Jadwal: ${_destinationNote!.plannedDate}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: primaryDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _destinationNote!.noteText,
                    style: const TextStyle(
                      fontSize: 13,
                      color: textPrimary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tersimpan di File: $_localFilePath\nDiperbarui: ${_destinationNote!.updatedAt}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showNoteEditorDialog(item),
              icon: Icon(
                _destinationNote == null
                    ? Icons.note_add_outlined
                    : Icons.edit_outlined,
                size: 16,
                color: Colors.white,
              ),
              label: Text(
                _destinationNote == null
                    ? 'Tulis Catatan Rencana Kunjungan'
                    : 'Edit Catatan di File Lokal',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(DestinationModel item, List<String> gallery) {
    return Stack(
      children: [
        Image.network(
          gallery[_selectedGalleryIndex],
          height: 330,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            height: 330,
            color: primaryLight,
            child: const Center(
              child: Icon(Icons.broken_image, size: 50, color: primaryTeal),
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 100,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.45),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 36,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.camera_alt, color: Colors.white, size: 13),
                const SizedBox(width: 5),
                Text(
                  '${_selectedGalleryIndex + 1}/${gallery.length} Foto',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingTopBar(DestinationModel item) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCircleButton(
                icon: Icons.arrow_back_ios_new,
                iconSize: 18,
                onTap: () => Navigator.pop(context),
              ),
              Row(
                children: [
                  _buildCircleButton(
                    icon: Icons.share_outlined,
                    iconSize: 18,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Tautan ${item.name} siap dibagikan!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  _buildCircleButton(
                    icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
                    iconColor: _isFavorite ? favoriteRed : textPrimary,
                    iconSize: 20,
                    onTap: () => _toggleFavorite(item),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = textPrimary,
    double iconSize = 18,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: surfaceWhite.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: iconSize),
      ),
    );
  }

  Widget _buildCategoryAndPriceRow(DestinationModel item) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: primaryLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            item.category.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: primaryDark,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Text(
          item.formattedPrice,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: primaryTeal,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStatBadges(DestinationModel item) {
    return Row(
      children: [
        Expanded(
          child: _buildBadgeCard(
            icon: Icons.star_rounded,
            iconColor: accentAmber,
            title: '${item.rating} / 5.0',
            subtitle: '${item.reviewCount} ulasan',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildBadgeCard(
            icon: Icons.access_time_filled_rounded,
            iconColor: primaryTeal,
            title: 'Jam Buka',
            subtitle: item.openHours,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildBadgeCard(
            icon: Icons.explore,
            iconColor: tertiaryTerracotta,
            title: item.district,
            subtitle: item.city,
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: backgroundLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderSubtle),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryThumbnails(List<String> gallery) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Galeri Foto',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 64,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: gallery.length,
            itemBuilder: (context, index) {
              final isSelected = _selectedGalleryIndex == index;
              return Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedGalleryIndex = index;
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? primaryTeal : borderSubtle,
                        width: isSelected ? 2.5 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        gallery[index],
                        width: 80,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 80,
                          height: 64,
                          color: primaryLight,
                          child: const Icon(
                            Icons.broken_image_outlined,
                            size: 24,
                            color: primaryTeal,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFacilitiesSection(DestinationModel item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fasilitas & Layanan',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: item.facilities.map((fac) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: backgroundLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderSubtle),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 14,
                    color: primaryTeal,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    fac,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGpsMapCard(DestinationModel item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryLight.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryTeal.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryTeal.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.near_me,
                  color: primaryDark,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Koordinat GPS Presisi',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: primaryDark,
                    ),
                  ),
                  Text(
                    'Titik Geografis Lokasi Destinasi',
                    style: TextStyle(fontSize: 11, color: textMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: surfaceWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderSubtle),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Latitude / Longitude:',
                      style: TextStyle(fontSize: 10, color: textMuted),
                    ),
                    Text(
                      '${item.latitude.toStringAsFixed(6)}, ${item.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 16, color: primaryTeal),
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(
                        text: '${item.latitude}, ${item.longitude}',
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Koordinat berhasil disalin ke clipboard!'),
                        duration: Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Membuka peta Google Maps ke koordinat ${item.latitude}, ${item.longitude}...',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.map_outlined, size: 16, color: primaryDark),
              label: const Text(
                'Buka di Google Maps',
                style: TextStyle(
                  color: primaryDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: primaryTeal),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(DestinationModel item) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: surfaceWhite,
          border: const Border(
            top: BorderSide(color: borderSubtle, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Biaya / Tiket',
                  style: TextStyle(fontSize: 11, color: textMuted),
                ),
                Text(
                  item.formattedPrice,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryDark,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Memulai panduan navigasi ke ${item.name}!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.navigation_rounded, color: Colors.white),
                label: const Text(
                  'Petunjuk Arah',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryTeal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
