import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/destination_model.dart';
import '../models/itinerary_note_model.dart';
import '../services/persistence_service.dart';
import 'category_page.dart';
import 'saved_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static const String routeName = '/';

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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

  List<DestinationModel> _allDestinations = [];
  List<DestinationModel> _filteredDestinations = [];
  Map<String, ItineraryNoteModel> _localNotes = {};
  bool _isLoading = true;
  String _selectedCategory = 'Semua';
  final TextEditingController _searchController = TextEditingController();

  String _currentKecamatan = 'Klojen';
  String _currentKota = 'Kota Malang';
  double _userLat = -7.9826;
  double _userLng = 112.6308;

  final List<String> _categories = [
    'Semua',
    'Wisata Alam',
    'Budaya & Edukasi',
    'Wahana Rekreasi',
    'Kuliner Legendaris',
    'Kafe & Santai',
  ];

  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadDestinationsAndPersistence();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Memuat katalog destinasi secara asinkron serta menyinkronkan data dari
  /// SharedPreferences dan berkas catatan lokal (Read and Write Files).
  Future<void> _loadDestinationsAndPersistence() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/data/destinations.json');
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;

      final List<DestinationModel> rawList = jsonList
          .map((item) => DestinationModel.fromJson(item as Map<String, dynamic>))
          .toList();

      // Ambil daftar favorit default dari JSON jika belum pernah diinisialisasi
      final List<String> defaultFavIds = rawList
          .where((item) => item.isFavorite)
          .map((item) => item.id)
          .toList();

      // 1. Baca data persisten dari SharedPreferences
      final List<String> savedFavIds =
          await PersistenceService.loadFavoriteIds(defaultFavIds);
      final String savedCategory = await PersistenceService.loadLastCategory();
      final Map<String, dynamic> savedLocation =
          await PersistenceService.loadUserLocation();

      // 2. Baca seluruh catatan rencana kunjungan dari File lokal
      final Map<String, ItineraryNoteModel> notesMap =
          await PersistenceService.readAllNotesFromFile();

      // Sinkronkan status isFavorite pada setiap objek destinasi
      final List<DestinationModel> syncedList = rawList.map((item) {
        return item.copyWith(isFavorite: savedFavIds.contains(item.id));
      }).toList();

      if (!mounted) return;
      setState(() {
        _allDestinations = syncedList;
        _selectedCategory =
            _categories.contains(savedCategory) ? savedCategory : 'Semua';
        _currentKecamatan = savedLocation['district'] as String;
        _currentKota = savedLocation['city'] as String;
        _userLat = savedLocation['latitude'] as double;
        _userLng = savedLocation['longitude'] as double;
        _localNotes = notesMap;
        _isLoading = false;
      });
      _applyFilter();
    } catch (e) {
      debugPrint('Gagal memuat data aplikasi: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Menyinkronkan ulang status favorit (SharedPreferences) dan catatan (File)
  /// setelah pengguna kembali dari halaman detail.
  Future<void> _syncPersistenceState() async {
    final List<String> defaultFavIds = _allDestinations
        .where((item) => item.isFavorite)
        .map((item) => item.id)
        .toList();
    final List<String> savedFavIds =
        await PersistenceService.loadFavoriteIds(defaultFavIds);
    final Map<String, ItineraryNoteModel> notesMap =
        await PersistenceService.readAllNotesFromFile();

    if (!mounted) return;
    setState(() {
      _allDestinations = _allDestinations.map((item) {
        return item.copyWith(isFavorite: savedFavIds.contains(item.id));
      }).toList();
      _localNotes = notesMap;
    });
    _applyFilter();
  }

  /// Logika filter gabungan berdasarkan kata kunci pencarian dan kategori
  void _applyFilter() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filteredDestinations = _allDestinations.where((item) {
        final matchesCategory =
            _selectedCategory == 'Semua' || item.category == _selectedCategory;
        final matchesQuery = query.isEmpty ||
            item.name.toLowerCase().contains(query) ||
            item.district.toLowerCase().contains(query) ||
            item.city.toLowerCase().contains(query) ||
            item.category.toLowerCase().contains(query);
        return matchesCategory && matchesQuery;
      }).toList();
    });
  }

  /// Mengubah status favorit destinasi dan menyimpannya secara persisten ke SharedPreferences
  Future<void> _toggleBookmark(String id) async {
    setState(() {
      final index = _allDestinations.indexWhere((item) => item.id == id);
      if (index != -1) {
        final currentFav = _allDestinations[index].isFavorite;
        _allDestinations[index] =
            _allDestinations[index].copyWith(isFavorite: !currentFav);
        _applyFilter();
      }
    });

    final List<String> updatedFavIds = _allDestinations
        .where((item) => item.isFavorite)
        .map((item) => item.id)
        .toList();
    await PersistenceService.saveFavoriteIds(updatedFavIds);

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Daftar favorit berhasil disimpan ke SharedPreferences!'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Memperbarui lokasi pengguna dan menyimpannya ke SharedPreferences
  Future<void> _refreshLocation() async {
    final bool isMalang = _currentKecamatan == 'Klojen';
    final String nextDistrict = isMalang ? 'Batu' : 'Klojen';
    final String nextCity = isMalang ? 'Kota Wisata Batu' : 'Kota Malang';
    final double nextLat = isMalang ? -7.8712 : -7.9826;
    final double nextLng = isMalang ? 112.5273 : 112.6308;

    setState(() {
      _currentKecamatan = nextDistrict;
      _currentKota = nextCity;
      _userLat = nextLat;
      _userLng = nextLng;
    });

    await PersistenceService.saveUserLocation(
      district: nextDistrict,
      city: nextCity,
      latitude: nextLat,
      longitude: nextLng,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Lokasi disimpan di SharedPreferences: $nextDistrict, $nextCity',
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Membuka halaman detail dan menyinkronkan data persisten saat kembali
  Future<void> _openDetailPage(DestinationModel item) async {
    await Navigator.pushNamed(
      context,
      '/detail',
      arguments: item,
    );
    await _syncPersistenceState();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: backgroundLight,
        body: Center(
          child: CircularProgressIndicator(color: primaryTeal),
        ),
      );
    }

    // IndexedStack mempertahankan state seluruh 4 tab navigasi utama
    return Scaffold(
      backgroundColor: backgroundLight,
      body: IndexedStack(
        index: _currentNavIndex,
        children: [
          // Tab 0: Beranda (Home)
          SafeArea(child: _buildHomeTabContent()),

          // Tab 1: Eksplor (Category Page)
          CategoryPage(
            isStandalone: false,
            initialItems: _allDestinations,
            onToggleBookmark: _toggleBookmark,
            onDataChanged: _syncPersistenceState,
            userLat: _userLat,
            userLng: _userLng,
          ),

          // Tab 2: Disimpan (Saved / Bookmarks Page)
          SavedPage(
            initialItems: _allDestinations,
            localNotes: _localNotes,
            onToggleBookmark: _toggleBookmark,
            onDataChanged: _syncPersistenceState,
            onExploreTap: () {
              setState(() {
                _currentNavIndex = 0;
              });
            },
            isStandalone: false,
          ),

          // Tab 3: Akun (Profile Mahasiswa & Diagnostik Penyimpanan)
          ProfilePage(
            savedCount: _allDestinations.where((d) => d.isFavorite).length,
            notesCount: _localNotes.length,
            currentCity: _currentKota,
            currentDistrict: _currentKecamatan,
            onOpenSaved: () {
              setState(() {
                _currentNavIndex = 2;
              });
            },
            onResetPersistence: () async {
              await PersistenceService.resetAllPersistenceData();
              await _loadDestinationsAndPersistence();
            },
            isStandalone: false,
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  /// Konten Utama Tab Beranda
  Widget _buildHomeTabContent() {
    return RefreshIndicator(
      color: primaryTeal,
      onRefresh: _loadDestinationsAndPersistence,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Lokasi GPS & Indikator Data Persistence
              _buildLocationHeader(),

              const SizedBox(height: 16),

              // 2. Greeting & Search Bar
              _buildHeroSearchSection(),

              const SizedBox(height: 20),

              // 3. Filter Kategori (Horizontal Chips)
              _buildCategoryFilter(),

              const SizedBox(height: 24),

              // 4. Seksi Destinasi Populer (Horizontal Carousel)
              _buildFeaturedSection(),

              const SizedBox(height: 24),

              // 5. Seksi Kuliner Legendaris (Vertical Feed)
              _buildCulinarySection(),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Menampilkan chip lokasi pengguna saat ini yang tersimpan di SharedPreferences
  Widget _buildLocationHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // GPS Location Pill
          InkWell(
            onTap: _refreshLocation,
            borderRadius: BorderRadius.circular(50),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: primaryLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: primaryTeal.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on,
                    color: primaryTeal,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$_currentKecamatan, $_currentKota',
                    style: const TextStyle(
                      color: primaryDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.sync_rounded,
                    color: primaryDark,
                    size: 15,
                  ),
                ],
              ),
            ),
          ),

          // Tombol Info Status Penyimpanan Lokal
          Container(
            decoration: BoxDecoration(
              color: surfaceWhite,
              shape: BoxShape.circle,
              border: Border.all(color: borderSubtle),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.storage_rounded),
              color: primaryTeal,
              iconSize: 20,
              tooltip: 'Status Penyimpanan Lokal',
              onPressed: () {
                final favCount =
                    _allDestinations.where((d) => d.isFavorite).length;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Data Persistence Aktif: $favCount Favorit (SharedPrefs) & ${_localNotes.length} Catatan (File JSON)',
                    ),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSearchSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Halo, Petualang! 🌿',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textMuted,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Eksplor Wisata & Kuliner',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderSubtle),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _applyFilter(),
              decoration: InputDecoration(
                hintText: 'Cari destinasi, bakso, kafe...',
                hintStyle: const TextStyle(color: textMuted, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: primaryTeal),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilter();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                });
                _applyFilter();
                PersistenceService.saveLastCategory(category);
              },
              borderRadius: BorderRadius.circular(50),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? primaryTeal : surfaceWhite,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: isSelected ? primaryTeal : borderSubtle,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: primaryTeal.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    category,
                    style: TextStyle(
                      color: isSelected ? Colors.white : textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedSection() {
    final featuredItems =
        _filteredDestinations.where((item) => item.rating >= 4.7).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Destinasi Populer ⭐',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    _currentNavIndex = 1;
                  });
                },
                child: const Text(
                  'Lihat Semua',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: primaryTeal,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        featuredItems.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Text('Tidak ada destinasi yang cocok.'),
              )
            : SizedBox(
                height: 270,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: featuredItems.length,
                  itemBuilder: (context, index) {
                    final item = featuredItems[index];
                    return _buildFeaturedCard(item);
                  },
                ),
              ),
      ],
    );
  }

  Widget _buildFeaturedCard(DestinationModel item) {
    final bool hasNote = _localNotes.containsKey(item.id);

    return Container(
      width: 210,
      margin: const EdgeInsets.only(right: 14, bottom: 6),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderSubtle),
        ),
        color: surfaceWhite,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openDetailPage(item),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Foto Destinasi dengan overlay bookmark dan rating
              Stack(
                children: [
                  Image.network(
                    item.imageUrl,
                    height: 130,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 130,
                      color: primaryLight,
                      child: const Center(
                        child: Icon(Icons.broken_image, color: primaryTeal),
                      ),
                    ),
                  ),
                  // Rating Badge
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: accentAmber,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.rating.toString(),
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
                  // Indikator Catatan Lokal Tersimpan (jika ada)
                  if (hasNote)
                    Positioned(
                      bottom: 8,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: primaryDark.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.edit_note_rounded,
                              color: Colors.white,
                              size: 12,
                            ),
                            SizedBox(width: 3),
                            Text(
                              'Catatan',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Tombol Favorit
                  Positioned(
                    top: 8,
                    right: 8,
                    child: InkWell(
                      onTap: () => _toggleBookmark(item.id),
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: surfaceWhite.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: item.isFavorite ? favoriteRed : textMuted,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Detail Teks
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.category.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: primaryTeal,
                        letterSpacing: 0.5,
                      ),
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
                        const Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: textMuted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${item.district}, ${item.city}',
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
                    const SizedBox(height: 8),
                    Text(
                      item.formattedPrice,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCulinarySection() {
    final culinaryItems = _filteredDestinations
        .where((item) =>
            item.category == 'Kuliner Legendaris' ||
            item.category == 'Kafe & Santai')
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Kuliner Legendaris Khas 🍜',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    _selectedCategory = 'Kuliner Legendaris';
                  });
                  _applyFilter();
                  PersistenceService.saveLastCategory('Kuliner Legendaris');
                },
                child: const Text(
                  'Filter Kuliner',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: primaryTeal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: culinaryItems.length,
            itemBuilder: (context, index) {
              final item = culinaryItems[index];
              return _buildCulinaryListCard(item);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCulinaryListCard(DestinationModel item) {
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
          onTap: () => _openDetailPage(item),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    item.imageUrl,
                    width: 84,
                    height: 84,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 84,
                      height: 84,
                      color: primaryLight,
                      child: const Icon(Icons.restaurant, color: primaryTeal),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => _toggleBookmark(item.id),
                            child: Icon(
                              item.isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: item.isFavorite ? favoriteRed : textMuted,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 12,
                            color: textMuted,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.openHours,
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
                          Text(
                            item.formattedPrice,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: primaryTeal,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: accentAmber,
                                size: 16,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${item.rating}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
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

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: surfaceWhite,
        border: const Border(
          top: BorderSide(color: borderSubtle, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          setState(() {
            _currentNavIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: surfaceWhite,
        selectedItemColor: primaryTeal,
        unselectedItemColor: textMuted,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 11,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Eksplor',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_outline),
            activeIcon: Icon(Icons.bookmark),
            label: 'Disimpan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Akun',
          ),
        ],
      ),
    );
  }
}
