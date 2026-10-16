import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/destination_model.dart';
import '../models/itinerary_note_model.dart';
import '../services/persistence_service.dart';
import 'detail_page.dart';

class SavedPage extends StatefulWidget {
  final List<DestinationModel>? initialItems;
  final Map<String, ItineraryNoteModel>? localNotes;
  final Function(String id)? onToggleBookmark;
  final VoidCallback? onDataChanged;
  final VoidCallback? onExploreTap;
  final bool isStandalone;

  const SavedPage({
    super.key,
    this.initialItems,
    this.localNotes,
    this.onToggleBookmark,
    this.onDataChanged,
    this.onExploreTap,
    this.isStandalone = false,
  });

  static const String routeName = '/saved';

  @override
  State<SavedPage> createState() => _SavedPageState();
}

class _SavedPageState extends State<SavedPage> {
  static const Color primaryTeal = Color(0xFF0D9488);
  static const Color primaryDark = Color(0xFF0F766E);
  static const Color primaryLight = Color(0xFFCCFBF1);
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color borderSubtle = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color favoriteRed = Color(0xFFEF4444);

  List<DestinationModel> _savedItems = [];
  Map<String, ItineraryNoteModel> _notesMap = {};
  bool _isLoading = true;
  String _selectedFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    if (widget.initialItems != null) {
      _savedItems =
          widget.initialItems!.where((item) => item.isFavorite).toList();
      _notesMap = widget.localNotes ?? {};
      _isLoading = false;
    } else {
      _loadSavedFromPersistence();
    }
  }

  @override
  void didUpdateWidget(covariant SavedPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialItems != null) {
      setState(() {
        _savedItems =
            widget.initialItems!.where((item) => item.isFavorite).toList();
        _notesMap = widget.localNotes ?? _notesMap;
      });
    }
  }

  /// Membaca data destinasi favorit dari SharedPreferences dan catatan dari File lokal
  /// jika halaman dibuka sebagai rute mandiri (/saved).
  Future<void> _loadSavedFromPersistence() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/data/destinations.json');
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
      final List<DestinationModel> all = jsonList
          .map((e) => DestinationModel.fromJson(e as Map<String, dynamic>))
          .toList();

      final List<String> defaultFavs =
          all.where((e) => e.isFavorite).map((e) => e.id).toList();
      final List<String> savedFavIds =
          await PersistenceService.loadFavoriteIds(defaultFavs);
      final Map<String, ItineraryNoteModel> loadedNotes =
          await PersistenceService.readAllNotesFromFile();

      if (!mounted) return;
      setState(() {
        _savedItems = all
            .where((item) => savedFavIds.contains(item.id))
            .map((item) => item.copyWith(isFavorite: true))
            .toList();
        _notesMap = loadedNotes;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading saved items: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Menghapus destinasi dari daftar favorit di SharedPreferences
  Future<void> _handleRemoveBookmark(DestinationModel item) async {
    if (widget.onToggleBookmark != null) {
      widget.onToggleBookmark!(item.id);
    } else {
      await PersistenceService.toggleFavoriteId(item.id);
      if (!mounted) return;
      setState(() {
        _savedItems.removeWhere((element) => element.id == item.id);
      });
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} dihapus dari daftar favorit.'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'BATAL',
          textColor: accentAmber,
          onPressed: () {
            if (widget.onToggleBookmark != null) {
              widget.onToggleBookmark!(item.id);
            } else {
              PersistenceService.toggleFavoriteId(item.id).then((_) {
                _loadSavedFromPersistence();
              });
            }
          },
        ),
      ),
    );
  }

  List<DestinationModel> get _filteredList {
    if (_selectedFilter == 'Wisata Alam') {
      return _savedItems.where((i) => i.category == 'Wisata Alam').toList();
    } else if (_selectedFilter == 'Kuliner') {
      return _savedItems
          .where((i) =>
              i.category == 'Kuliner Legendaris' ||
              i.category == 'Kafe & Santai')
          .toList();
    }
    return _savedItems;
  }

  @override
  Widget build(BuildContext context) {
    final alamCount =
        _savedItems.where((i) => i.category == 'Wisata Alam').length;
    final kulinerCount = _savedItems
        .where((i) =>
            i.category == 'Kuliner Legendaris' ||
            i.category == 'Kafe & Santai')
        .length;

    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        backgroundColor: surfaceWhite,
        elevation: 0,
        automaticallyImplyLeading: widget.isStandalone,
        leading: widget.isStandalone
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: textPrimary, size: 18),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Column(
          children: [
            const Text(
              'Destinasi Disimpan',
              style: TextStyle(
                color: textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_savedItems.length} Tempat Tersimpan (SharedPreferences)',
              style: const TextStyle(
                color: textMuted,
                fontSize: 11.5,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderSubtle, height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryTeal))
          : _savedItems.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    const SizedBox(height: 12),

                    // 1. Horizontal Filter Chips (Semua, Wisata Alam, Kuliner)
                    _buildFilterChips(alamCount, kulinerCount),

                    const SizedBox(height: 8),

                    // 2. Daftar Kartu Destinasi Tersimpan (ListView.builder)
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: _filteredList.length,
                        itemBuilder: (context, index) {
                          final item = _filteredList[index];
                          return _buildSavedCard(item);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  /// Ditampilkan jika pengguna belum menandai destinasi favorit
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primaryLight.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bookmark_border_rounded,
                size: 64,
                color: primaryTeal,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Belum Ada Destinasi Disimpan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tekan ikon hati pada kartu destinasi wisata atau kuliner yang ingin Anda simpan ke dalam SharedPreferences.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                if (widget.onExploreTap != null) {
                  widget.onExploreTap!();
                } else {
                  Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.explore_outlined, color: Colors.white),
              label: const Text(
                'Mulai Eksplorasi Sekarang',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTeal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(int alamCount, int kulinerCount) {
    final filters = [
      {'name': 'Semua', 'count': _savedItems.length},
      {'name': 'Wisata Alam', 'count': alamCount},
      {'name': 'Kuliner', 'count': kulinerCount},
    ];

    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final f = filters[index];
          final name = f['name'] as String;
          final count = f['count'] as int;
          final isSelected = _selectedFilter == name;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedFilter = name;
                });
              },
              borderRadius: BorderRadius.circular(50),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? primaryTeal : surfaceWhite,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: isSelected ? primaryTeal : borderSubtle,
                  ),
                ),
                child: Text(
                  '$name ($count)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : textPrimary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSavedCard(DestinationModel item) {
    final ItineraryNoteModel? savedNote = _notesMap[item.id];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderSubtle),
        ),
        color: surfaceWhite,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () async {
            await Navigator.pushNamed(
              context,
              DetailPage.routeName,
              arguments: item,
            );
            if (widget.onDataChanged != null) {
              widget.onDataChanged!();
            } else {
              await _loadSavedFromPersistence();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Thumbnail Gambar Bersudut Lengkung
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        item.imageUrl,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 90,
                          height: 90,
                          color: primaryLight,
                          child: const Icon(Icons.place, color: primaryTeal),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // 2. Info Teks Destinasi
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item.category.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: primaryTeal,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () => _handleRemoveBookmark(item),
                                child: const Icon(
                                  Icons.favorite,
                                  color: favoriteRed,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: accentAmber, size: 14),
                              const SizedBox(width: 2),
                              Text(
                                '${item.rating}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '(${item.reviewCount} ulasan)',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item.formattedPrice,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: primaryDark,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: primaryLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.directions,
                                        size: 12, color: primaryDark),
                                    SizedBox(width: 4),
                                    Text(
                                      'Petunjuk Rute',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: primaryDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (savedNote != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: accentAmber.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.edit_note_rounded,
                          size: 16,
                          color: Color(0xFFB45309),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '[${savedNote.plannedDate}] ${savedNote.noteText}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: textPrimary,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
