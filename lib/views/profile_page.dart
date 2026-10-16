import 'package:flutter/material.dart';
import '../services/persistence_service.dart';

class ProfilePage extends StatelessWidget {
  final int savedCount;
  final int notesCount;
  final String currentCity;
  final String currentDistrict;
  final VoidCallback? onOpenSaved;
  final Future<void> Function()? onResetPersistence;
  final bool isStandalone;

  const ProfilePage({
    super.key,
    this.savedCount = 4,
    this.notesCount = 2,
    this.currentCity = 'Kota Malang',
    this.currentDistrict = 'Klojen',
    this.onOpenSaved,
    this.onResetPersistence,
    this.isStandalone = false,
  });

  static const String routeName = '/profile';

  static const Color primaryTeal = Color(0xFF0D9488);
  static const Color primaryDark = Color(0xFF0F766E);
  static const Color primaryLight = Color(0xFFCCFBF1);
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color borderSubtle = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color dangerRed = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        backgroundColor: surfaceWhite,
        elevation: 0,
        automaticallyImplyLeading: isStandalone,
        leading: isStandalone
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: textPrimary, size: 18),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'Profil Saya',
          style: TextStyle(
            color: textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: textPrimary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pengaturan aplikasi LokaNusantara v1.0.0'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderSubtle, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          children: [
            // 1. Kartu Header Profil Mahasiswa
            _buildProfileHeader(context),

            const SizedBox(height: 16),

            // 2. Baris Statistik Cepat (3 Kolom Proporsional)
            _buildQuickStatRow(),

            const SizedBox(height: 20),

            // 3. Seksi Menu: Eksplorasi & Preferensi
            _buildMenuSection(
              title: 'Eksplorasi & Preferensi Pengguna',
              items: [
                _MenuItem(
                  icon: Icons.bookmark_added_outlined,
                  iconColor: primaryTeal,
                  title: 'Koleksi Favorit Saya (SharedPreferences)',
                  subtitle: '$savedCount destinasi tersimpan secara persisten',
                  onTap: () {
                    if (onOpenSaved != null) {
                      onOpenSaved!();
                    } else {
                      Navigator.pushNamed(context, '/saved');
                    }
                  },
                ),
                _MenuItem(
                  icon: Icons.my_location_outlined,
                  iconColor: const Color(0xFF3B82F6),
                  title: 'Preferensi Lokasi Aktif',
                  subtitle: '$currentDistrict, $currentCity',
                  onTap: () => _showGpsInfoDialog(context),
                ),
                _MenuItem(
                  icon: Icons.folder_special_outlined,
                  iconColor: accentAmber,
                  title: 'Berkas Catatan Rencana Kunjungan',
                  subtitle:
                      '$notesCount catatan di ${PersistenceService.localNotesFileName}',
                  onTap: () => _showPersistenceDiagnosticsDialog(context),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 4. Seksi Menu: Penyimpanan Lokal & Informasi Aplikasi
            _buildMenuSection(
              title: 'Penyimpanan Lokal & Informasi Aplikasi',
              items: [
                _MenuItem(
                  icon: Icons.storage_rounded,
                  iconColor: const Color(0xFF8B5CF6),
                  title: 'Status Data Persistence (SharedPrefs & File I/O)',
                  subtitle: '2 Teknik Penyimpanan Lokal Aktif & Terverifikasi',
                  badgeText: 'AKTIF',
                  onTap: () => _showPersistenceDiagnosticsDialog(context),
                ),
                _MenuItem(
                  icon: Icons.info_outline,
                  iconColor: primaryDark,
                  title: 'Tentang Aplikasi LokaNusantara',
                  subtitle: 'Versi 1.0.0 (UTS Pemrograman Multiplatform)',
                  onTap: () => _showAboutDialog(context),
                ),
                _MenuItem(
                  icon: Icons.restart_alt_outlined,
                  iconColor: dangerRed,
                  title: 'Reset Data Penyimpanan Lokal',
                  subtitle:
                      'Bersihkan SharedPreferences & file catatan kunjungan',
                  isDestructive: true,
                  onTap: () => _showResetDialog(context),
                ),
              ],
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: borderSubtle),
      ),
      color: surfaceWhite,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: primaryTeal, width: 2.5),
              ),
              child: const CircleAvatar(
                radius: 40,
                backgroundColor: primaryLight,
                child: Icon(
                  Icons.person,
                  size: 48,
                  color: primaryTeal,
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Muhammad Nailul Ghufron Majid',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'NIM: 240605110160 • Teknik Informatika',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: textMuted,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: primaryLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primaryTeal.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.school, size: 14, color: primaryDark),
                  SizedBox(width: 6),
                  Text(
                    'UIN Maulana Malik Ibrahim Malang',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: primaryDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            value: '$savedCount',
            label: 'Disimpan',
            icon: Icons.bookmark,
            color: primaryTeal,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatItem(
            value: '16',
            label: 'Destinasi',
            icon: Icons.place_rounded,
            color: const Color(0xFF3B82F6),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatItem(
            value: '$notesCount',
            label: 'Catatan File',
            icon: Icons.edit_note_rounded,
            color: accentAmber,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderSubtle),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection({
    required String title,
    required List<_MenuItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: textMuted,
              letterSpacing: 0.3,
            ),
          ),
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: borderSubtle),
          ),
          color: surfaceWhite,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: items.map((item) {
              final isLast = items.indexOf(item) == items.length - 1;
              return Column(
                children: [
                  ListTile(
                    onTap: item.onTap,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: item.iconColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item.icon, color: item.iconColor, size: 20),
                    ),
                    title: Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: item.isDestructive ? dangerRed : textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      item.subtitle,
                      style: const TextStyle(fontSize: 12, color: textMuted),
                    ),
                    trailing: item.badgeText != null
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: primaryLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.badgeText!,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: primaryDark,
                              ),
                            ),
                          )
                        : const Icon(Icons.chevron_right,
                            color: textMuted, size: 18),
                  ),
                  if (!isLast)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      indent: 56,
                      color: borderSubtle,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _showGpsInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.location_on, color: primaryTeal),
            SizedBox(width: 8),
            Text('Preferensi Lokasi Tersimpan'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Disimpan secara persisten di SharedPreferences:'),
            const SizedBox(height: 8),
            Text('• Kecamatan: $currentDistrict'),
            Text('• Wilayah: $currentCity'),
            const Text('• Key: pref_user_district & pref_user_city'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup', style: TextStyle(color: primaryTeal)),
          ),
        ],
      ),
    );
  }

  /// Menampilkan dialog diagnostik nyata untuk kedua teknik Data Persistence
  Future<void> _showPersistenceDiagnosticsDialog(BuildContext context) async {
    final Map<String, dynamic> diag =
        await PersistenceService.getStorageDiagnostics();
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Diagnostik Data Persistence',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '1. Shared Preferences (Key-Value Storage)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: primaryDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '• Destinasi Favorit: ${diag['favoriteCount']} ID tersimpan\n'
                '• Filter Kategori Terakhir: ${diag['lastCategory']}\n'
                '• Lokasi Aktif: ${diag['savedLocation']}',
                style: const TextStyle(fontSize: 12, height: 1.45),
              ),
              const SizedBox(height: 14),
              const Text(
                '2. Read and Write Files (File System Storage)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: primaryDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '• Nama File: ${PersistenceService.localNotesFileName}\n'
                '• Jumlah Catatan Kunjungan: ${diag['notesCount']} item\n'
                '• Ukuran Berkas: ${diag['fileSizeBytes']} bytes\n'
                '• Path Direktori: ${diag['filePath']}',
                style: const TextStyle(fontSize: 12, height: 1.45),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: primaryTeal),
            child: const Text('Tutup', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'LokaNusantara',
      applicationVersion: '1.0.0 (UTS Pemrograman Multiplatform)',
      applicationLegalese:
          '© 2026 Muhammad Nailul Ghufron Majid - UIN Maulana Malik Ibrahim Malang',
      children: const [
        SizedBox(height: 10),
        Text(
          'Aplikasi rekomendasi destinasi wisata dan kuliner lokal Malang Raya berbasis Flutter dan Dart dengan penerapan Asynchronous Programming serta dua teknik Data Persistence (Shared Preferences dan Read & Write Files).',
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Reset Data Persistence'),
        content: const Text(
          'Apakah Anda yakin ingin mengatur ulang seluruh data SharedPreferences dan mengosongkan berkas catatan kunjungan lokal?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (onResetPersistence != null) {
                await onResetPersistence!();
              } else {
                await PersistenceService.resetAllPersistenceData();
              }
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Data SharedPreferences dan file lokal berhasil diatur ulang.',
                  ),
                  backgroundColor: dangerRed,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: dangerRed),
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? badgeText;
  final bool isDestructive;
  final VoidCallback onTap;

  _MenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.badgeText,
    this.isDestructive = false,
    required this.onTap,
  });
}
