# 🌿 LokaNusantara: Aplikasi Rekomendasi Destinasi Wisata & Kuliner Lokal (Malang Raya & Kota Batu)

> **Proyek Ujian Tengah Semester (UTS) - Pemrograman Multiplatform**  
> **Mata Kuliah:** Pemrograman Multiplatform  
> **Semester:** Ganjil 2025/2026  
> **Framework:** Flutter & Dart  
> **Konsep Utama:** *Asynchronous Programming* (`Future`, `async`/`await`) & *Data Persistence* (*Shared Preferences* dan *Read & Write Files*)  
> **Sistem Desain:** Emerald Teal (`#0D9488`), Warm Amber (`#F59E0B`), Terracotta (`#C36D4B`)

---

## 📌 1. Deskripsi & Tujuan Proyek

**LokaNusantara** adalah aplikasi mobile multiplatform berbasis Flutter dan Dart yang dirancang untuk memberikan rekomendasi komprehensif mengenai destinasi wisata unggulan (wisata alam, cagar budaya/sejarah, wahana rekreasi keluarga) serta kuliner legendaris otentik di wilayah Malang Raya dan Kota Wisata Batu, Jawa Timur.

### Tujuan & Pemenuhan Spesifikasi UTS Pemrograman Multiplatform:
1. **Asynchronous Programming:** Mengelola pemuatan data katalog JSON, pembacaan/penulisan preferensi pengguna, serta operasi I/O sistem berkas secara asinkron (`Future`, `async`, `await`, `try-catch`) tanpa memblokir *main UI thread*.
2. **Data Persistence — Teknik 1 (`Shared Preferences`):** Menyimpan secara permanen daftar ID destinasi favorit/disimpan (`pref_favorite_destination_ids`), kategori filter terakhir (`pref_last_selected_category`), dan lokasi aktif pengguna (`pref_user_district`, `pref_user_city`).
3. **Data Persistence — Teknik 2 (`Read and Write Files`):** Menyimpan, membaca, memperbarui, dan menghapus **Catatan Rencana Kunjungan (*Itinerary Note*)** pengguna secara langsung pada berkas fisik `catatan_wisata_lokanusantara.json` di direktori dokumen aplikasi (`path_provider` & `dart:io` `File`).

---

## 📱 2. Tampilan Antarmuka (User Interface)

| 1. Beranda (Home Page) | 2. Eksplor (Category Page) | 3. Detail & Catatan File (Detail Page) |
| :---: | :---: | :---: |
| ![Home Screen](assets/figma/home_page.png) | ![Category Screen](assets/figma/eksplor_page.png) | ![Detail Screen](assets/figma/detail_page.png) |

---

## 🗂️ 3. Struktur Proyek (Project Structure)

```text
UTS_Multiplatform_LokaNusantara/
├── assets/
│   ├── data/
│   │   └── destinations.json              # 16 Data konkret destinasi Malang & Batu
│   └── figma/                             # Aset visualisasi antarmuka & sistem desain
├── lib/
│   ├── models/
│   │   ├── destination_model.dart         # Model Class Destinasi (fromJson, toJson, copyWith)
│   │   └── itinerary_note_model.dart      # Model Class Catatan Rencana Kunjungan
│   ├── services/
│   │   └── persistence_service.dart       # Layanan Asynchronous, SharedPreferences, & File I/O
│   ├── views/
│   │   ├── home_page.dart                 # Beranda, Pencarian, Filter & Sinkronisasi State
│   │   ├── category_page.dart             # Eksplorasi Kategori & Pengurutan Dinamis
│   │   ├── detail_page.dart               # Detail Destinasi & Editor Catatan File Lokal
│   │   ├── saved_page.dart                # Daftar Favorit Persisten & Preview Catatan
│   │   └── profile_page.dart              # Profil Mahasiswa & Diagnostik Data Persistence
│   └── main.dart                          # Entry point, Tema Global, & Named Routes
├── test/
│   └── widget_test.dart                   # Pengujian otomatis widget Flutter
├── pubspec.yaml                           # Konfigurasi dependensi (shared_preferences, path_provider)
└── README.md                              # Dokumentasi utama proyek
```

---

## 📑 4. Rincian Fitur & Implementasi Teknis

1. **`PersistenceService` (`lib/services/persistence_service.dart`)**
   * Mengenkapsulasi seluruh operasi asinkron (`Future`, `async`/`await`).
   * Mengelola penyimpanan *key-value* menggunakan paket `shared_preferences`.
   * Mengelola pembacaan (`file.readAsString()`) dan penulisan (`file.writeAsString()`) berkas JSON lokal `catatan_wisata_lokanusantara.json` melalui `getApplicationDocumentsDirectory()` dari paket `path_provider`.
2. **`HomePage` (`lib/views/home_page.dart`)**
   * Memuat katalog destinasi, status favorit, kategori terakhir, lokasi pengguna, dan indikator catatan lokal secara asinkron saat `initState()`.
   * Menyediakan fitur pencarian *real-time*, filter kategori horizontal, *carousel* destinasi populer, dan daftar kuliner legendaris.
3. **`CategoryPage` (`lib/views/category_page.dart`)**
   * Menampilkan filter kategori dengan penghitung jumlah destinasi serta pengurutan dinamis (*Populer*, *Terdekat*, *Harga*, *Rating > 4.6*).
4. **`DetailPage` (`lib/views/detail_page.dart`)**
   * Menampilkan foto galeri, informasi tiket, jam buka, fasilitas, koordinat GPS, serta fitur **Catatan Rencana Kunjungan (Read & Write Files)** untuk menambah, mengedit, dan menghapus catatan pada berkas `catatan_wisata_lokanusantara.json`.
5. **`SavedPage` (`lib/views/saved_page.dart`)**
   * Menampilkan seluruh destinasi yang disimpan di `SharedPreferences` beserta ringkasan catatan kunjungan dari berkas lokal.
6. **`ProfilePage` (`lib/views/profile_page.dart`)**
   * Menampilkan identitas pengembang, statistik penyimpanan, dialog **Diagnostik Data Persistence**, dan fitur **Reset Penyimpanan Lokal**.

---

## 🚀 5. Cara Menjalankan Aplikasi

1. **Instalasi dependensi:**
   ```bash
   flutter pub get
   ```
2. **Analisis statis kode:**
   ```bash
   flutter analyze
   ```
3. **Pengujian otomatis:**
   ```bash
   flutter test
   ```
4. **Menjalankan aplikasi:**
   ```bash
   flutter run
   ```

---

## 👨‍💻 Identitas Pengembang
* **Nama Mahasiswa:** Muhammad Nailul Ghufron Majid
* **NIM:** 240605110160
* **Mata Kuliah:** Pemrograman Multiplatform
* **Institusi:** Jurusan Teknik Informatika, Fakultas Sains dan Teknologi, UIN Maulana Malik Ibrahim Malang
