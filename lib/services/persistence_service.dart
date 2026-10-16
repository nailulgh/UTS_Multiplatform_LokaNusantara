import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/itinerary_note_model.dart';

/// Layanan terpusat untuk menangani Asynchronous Programming dan Data Persistence:
/// 1. Shared Preferences: Menyimpan daftar ID favorit, filter kategori terakhir, dan lokasi pengguna.
/// 2. Read and Write Files: Menyimpan dan membaca berkas JSON catatan rencana kunjungan (catatan_wisata_lokanusantara.json).
class PersistenceService {
  static const String _keyFavoriteIds = 'pref_favorite_destination_ids';
  static const String _keyLastCategory = 'pref_last_selected_category';
  static const String _keyUserDistrict = 'pref_user_district';
  static const String _keyUserCity = 'pref_user_city';
  static const String _keyUserLat = 'pref_user_latitude';
  static const String _keyUserLng = 'pref_user_longitude';
  static const String _keyInitializedFavorites = 'pref_favorites_initialized';

  static const String localNotesFileName = 'catatan_wisata_lokanusantara.json';

  // ===========================================================================
  // TEKNIK 1: SHARED PREFERENCES (KEY-VALUE PERSISTENCE)
  // ===========================================================================

  /// Mengambil daftar ID destinasi favorit yang tersimpan di SharedPreferences.
  /// Jika pertama kali dijalankan, menginisialisasi dari daftar default JSON.
  static Future<List<String>> loadFavoriteIds(List<String> defaultIds) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final bool isInitialized = prefs.getBool(_keyInitializedFavorites) ?? false;

      if (!isInitialized) {
        await prefs.setStringList(_keyFavoriteIds, defaultIds);
        await prefs.setBool(_keyInitializedFavorites, true);
        return defaultIds;
      }

      return prefs.getStringList(_keyFavoriteIds) ?? <String>[];
    } catch (e) {
      debugPrint('Gagal membaca favorite IDs dari SharedPreferences: $e');
      return defaultIds;
    }
  }

  /// Menyimpan seluruh daftar ID destinasi favorit ke SharedPreferences.
  static Future<void> saveFavoriteIds(List<String> favoriteIds) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_keyFavoriteIds, favoriteIds);
      await prefs.setBool(_keyInitializedFavorites, true);
    } catch (e) {
      debugPrint('Gagal menyimpan favorite IDs ke SharedPreferences: $e');
    }
  }

  /// Mengubah status favorit satu destinasi di SharedPreferences dan mengembalikan status terbaru.
  static Future<bool> toggleFavoriteId(String destinationId) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> currentIds =
          List<String>.from(prefs.getStringList(_keyFavoriteIds) ?? <String>[]);

      bool isNowFavorite;
      if (currentIds.contains(destinationId)) {
        currentIds.remove(destinationId);
        isNowFavorite = false;
      } else {
        currentIds.add(destinationId);
        isNowFavorite = true;
      }

      await prefs.setStringList(_keyFavoriteIds, currentIds);
      await prefs.setBool(_keyInitializedFavorites, true);
      return isNowFavorite;
    } catch (e) {
      debugPrint('Gagal memperbarui status favorit di SharedPreferences: $e');
      return false;
    }
  }

  /// Menyimpan filter kategori terakhir yang dipilih pengguna ke SharedPreferences.
  static Future<void> saveLastCategory(String category) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastCategory, category);
    } catch (e) {
      debugPrint('Gagal menyimpan kategori terakhir: $e');
    }
  }

  /// Membaca filter kategori terakhir yang dipilih pengguna dari SharedPreferences.
  static Future<String> loadLastCategory() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyLastCategory) ?? 'Semua';
    } catch (e) {
      return 'Semua';
    }
  }

  /// Menyimpan preferensi lokasi aktif pengguna ke SharedPreferences.
  static Future<void> saveUserLocation({
    required String district,
    required String city,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUserDistrict, district);
      await prefs.setString(_keyUserCity, city);
      await prefs.setDouble(_keyUserLat, latitude);
      await prefs.setDouble(_keyUserLng, longitude);
    } catch (e) {
      debugPrint('Gagal menyimpan lokasi pengguna: $e');
    }
  }

  /// Membaca preferensi lokasi pengguna dari SharedPreferences.
  static Future<Map<String, dynamic>> loadUserLocation() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return {
        'district': prefs.getString(_keyUserDistrict) ?? 'Klojen',
        'city': prefs.getString(_keyUserCity) ?? 'Kota Malang',
        'latitude': prefs.getDouble(_keyUserLat) ?? -7.9826,
        'longitude': prefs.getDouble(_keyUserLng) ?? 112.6308,
      };
    } catch (e) {
      return {
        'district': 'Klojen',
        'city': 'Kota Malang',
        'latitude': -7.9826,
        'longitude': 112.6308,
      };
    }
  }

  // ===========================================================================
  // TEKNIK 2: READ AND WRITE FILES (PATH_PROVIDER & DART:IO FILE)
  // ===========================================================================

  /// Mendapatkan referensi objek File lokal pada direktori dokumen aplikasi.
  static Future<File> _getLocalNotesFile() async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      return File('${appDocDir.path}${Platform.pathSeparator}$localNotesFileName');
    } catch (e) {
      // Fallback ke direktori sistem sementara jika dijalankan pada lingkungan pengujian unit
      final Directory tempDir = Directory.systemTemp;
      return File('${tempDir.path}${Platform.pathSeparator}$localNotesFileName');
    }
  }

  /// Mengembalikan path lengkap berkas catatan lokal pada perangkat.
  static Future<String> getLocalNotesFilePath() async {
    final File file = await _getLocalNotesFile();
    return file.path;
  }

  /// Membaca seluruh catatan rencana kunjungan dari berkas lokal (Read File).
  static Future<Map<String, ItineraryNoteModel>> readAllNotesFromFile() async {
    try {
      final File file = await _getLocalNotesFile();
      final bool exists = await file.exists();

      if (!exists) {
        // Inisialisasi berkas awal dengan catatan contoh agar file langsung tersedia di perangkat
        final Map<String, ItineraryNoteModel> initialNotes = {
          'dest-001': const ItineraryNoteModel(
            destinationId: 'dest-001',
            destinationName: 'Taman Nasional Gunung Bromo',
            plannedDate: '25 Oktober 2026',
            noteText:
                'Berangkat pukul 00.30 WIB dari Kota Malang, sewa Jeep Hardtop via Tumpang, bawa jaket tebal dan sarung tangan.',
            updatedAt: '16 Okt 2026, 08:00 WIB',
          ),
          'dest-005': const ItineraryNoteModel(
            destinationId: 'dest-005',
            destinationName: 'Bakso President Malang',
            plannedDate: '26 Oktober 2026',
            noteText:
                'Makan siang bersama keluarga, wajib pesan Bakso Bakar Pedas dan Bakso Udang di tepi rel kereta.',
            updatedAt: '16 Okt 2026, 09:15 WIB',
          ),
        };
        await _writeMapToFile(file, initialNotes);
        return initialNotes;
      }

      final String rawContent = await file.readAsString();
      if (rawContent.trim().isEmpty) {
        return <String, ItineraryNoteModel>{};
      }

      final Map<String, dynamic> decoded =
          json.decode(rawContent) as Map<String, dynamic>;
      final Map<String, ItineraryNoteModel> notesMap = {};

      decoded.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          notesMap[key] = ItineraryNoteModel.fromJson(value);
        }
      });

      return notesMap;
    } catch (e) {
      debugPrint('Gagal membaca berkas catatan lokal: $e');
      return <String, ItineraryNoteModel>{};
    }
  }

  /// Membaca catatan rencana kunjungan untuk satu destinasi spesifik.
  static Future<ItineraryNoteModel?> readNoteForDestination(
      String destinationId) async {
    final Map<String, ItineraryNoteModel> allNotes = await readAllNotesFromFile();
    return allNotes[destinationId];
  }

  /// Menulis atau memperbarui catatan rencana kunjungan ke berkas lokal (Write File).
  static Future<void> writeNoteToFile(ItineraryNoteModel note) async {
    try {
      final File file = await _getLocalNotesFile();
      final Map<String, ItineraryNoteModel> currentNotes =
          await readAllNotesFromFile();
      currentNotes[note.destinationId] = note;
      await _writeMapToFile(file, currentNotes);
    } catch (e) {
      debugPrint('Gagal menulis catatan ke berkas lokal: $e');
    }
  }

  /// Menghapus catatan rencana kunjungan untuk satu destinasi dari berkas lokal.
  static Future<void> deleteNoteFromFile(String destinationId) async {
    try {
      final File file = await _getLocalNotesFile();
      final Map<String, ItineraryNoteModel> currentNotes =
          await readAllNotesFromFile();
      currentNotes.remove(destinationId);
      await _writeMapToFile(file, currentNotes);
    } catch (e) {
      debugPrint('Gagal menghapus catatan dari berkas lokal: $e');
    }
  }

  /// Helper internal untuk menulis Map catatan ke dalam berkas fisik dengan format JSON rapi.
  static Future<void> _writeMapToFile(
      File file, Map<String, ItineraryNoteModel> notes) async {
    final Map<String, dynamic> serializable = {};
    notes.forEach((key, value) {
      serializable[key] = value.toJson();
    });
    const JsonEncoder encoder = JsonEncoder.withIndent('  ');
    final String jsonString = encoder.convert(serializable);
    await file.writeAsString(jsonString, flush: true);
  }

  // ===========================================================================
  // DIAGNOSTIK & RESET PENYIMPANAN LOKAL
  // ===========================================================================

  /// Mengambil ringkasan diagnostik kedua teknik Data Persistence untuk ditampilkan di UI.
  static Future<Map<String, dynamic>> getStorageDiagnostics() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> favIds =
        prefs.getStringList(_keyFavoriteIds) ?? <String>[];
    final String lastCat = prefs.getString(_keyLastCategory) ?? 'Semua';
    final String district = prefs.getString(_keyUserDistrict) ?? 'Klojen';
    final String city = prefs.getString(_keyUserCity) ?? 'Kota Malang';

    final File file = await _getLocalNotesFile();
    final Map<String, ItineraryNoteModel> notes = await readAllNotesFromFile();
    final bool fileExists = await file.exists();
    final int fileSize = fileExists ? await file.length() : 0;

    return {
      'favoriteCount': favIds.length,
      'lastCategory': lastCat,
      'savedLocation': '$district, $city',
      'notesCount': notes.length,
      'filePath': file.path,
      'fileSizeBytes': fileSize,
    };
  }

  /// Mereset seluruh data SharedPreferences dan berkas catatan lokal ke kondisi awal.
  static Future<void> resetAllPersistenceData() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      final File file = await _getLocalNotesFile();
      if (await file.exists()) {
        await file.writeAsString('{}', flush: true);
      }
    } catch (e) {
      debugPrint('Gagal mereset data penyimpanan lokal: $e');
    }
  }
}
