# Nawaitu (Pelacak Ibadah Harian)

Aplikasi mobile pelacak dan pengingat kebiasaan ibadah harian berbasis **Flutter (Dart)** yang dibangun dengan arsitektur bersih (*Clean Code & Separation of Concerns*), navigasi rute terpusat (*Centralized Named Routes*), komponen UI modular (*Reusable Widgets*), dan sistem desain gradasi hijau Islami khas Nawaitu.

---

## 📑 Daftar Isi
1. [Arsitektur & Struktur Folder](#1-arsitektur--struktur-folder)
2. [Hubungan Antar-Folder dan Berkas](#2-hubungan-antar-folder-dan-berkas)
3. [Katalog Layar (Screens) & Pemakaian Reusable Widgets](#3-katalog-layar-screens--pemakaian-reusable-widgets)
4. [Sistem Navigasi (Tab Navigation vs Stack Navigation)](#4-sistem-navigasi-tab-navigation-vs-stack-navigation)
5. [Manajemen State (Stateful vs StatelessWidget & setState)](#5-manajemen-state-stateful-vs-statelesswidget--setstate)
6. [Sinkronus vs Asinkronus (Async, Await, Future)](#6-sinkronus-vs-asinkronus-async-await-future)
7. [Mutable vs Immutable Data](#7-mutable-vs-immutable-data)
8. [Peran Mock Data (Database Tiruan)](#8-peran-mock-data-database-tiruan)
9. [Enkapsulasi: Public vs Library-Private (Underscore `_`)](#9-enkapsulasi-public-vs-library-private-underscore-_)
10. [Penguncian Orientasi Layar (Portrait Lock)](#10-penguncian-orientasi-layar-portrait-lock)

---

## 1. Arsitektur & Struktur Folder

Struktur kode di dalam direktori `lib/` disusun berdasarkan prinsip pemisahan tanggung jawab:

```
lib/
├── core/
│   └── app_routes.dart             # Konstanta string nama rute terpusat
├── database/
│   └── mock_data.dart              # Data tiruan (dummy) sebagai in-memory database
├── models/
│   ├── history_model.dart          # Blueprint model data riwayat pelaksanaan ibadah
│   └── schedule_model.dart         # Blueprint model data jadwal ibadah
├── screens/
│   ├── create_schedule_screen.dart # Form pembuatan jadwal ibadah baru
│   ├── dashboard_screen.dart       # Layar beranda ringkasan & progres ibadah
│   ├── detail_history_screen.dart  # Layar rincian riwayat ibadah
│   ├── detail_schedule_screen.dart # Layar rincian jadwal terpilih
│   ├── edit_schedule_screen.dart   # Form pengubahan jadwal ibadah
│   ├── history_screen.dart         # Layar daftar riwayat ibadah
│   ├── main_navigation.dart        # Shell induk dengan BottomNavigationBar (3 Tab)
│   └── schedule_screen.dart        # Layar daftar jadwal ibadah
├── widgets/
│   ├── day_selector.dart           # Pemilih hari 7 chip melingkar (Interactive & Read-Only)
│   ├── description_card.dart       # Kontainer deskripsi pastel (Input & Display)
│   ├── empty_state_view.dart       # Tampilan ilustrasi saat data jadwal/riwayat kosong
│   ├── history_card.dart           # Kartu riwayat ibadah
│   ├── primary_button.dart         # Tombol utama hijau Nawaitu 52px
│   ├── schedule_card.dart          # Kartu jadwal ibadah dengan tombol switch toggle
│   ├── setting_tile.dart           # Baris pengaturan (Label + Kartu Opsi berikon)
│   ├── status_badge.dart           # Badge pill status (Terlaksana/Terlewat/Aktif/Nonaktif)
│   └── time_picker_card.dart       # Kartu putih penampil jam 56px & pemicu TimePicker
└── main.dart                       # Entry point aplikasi, tema Manrope, rute, & orientasi
```

---

## 2. Hubungan Antar-Folder dan Berkas

Aliran ketergantungan (*dependency flow*) aplikasi berjalan satu arah dari lapisan terbawah hingga lapisan teratas:

```
[ main.dart ] ──► Titik Masuk (Entry Point)
     │
     ├──► [ core/app_routes.dart ] ── Mendefinisikan nama string rute global
     │
     ├──► [ screens/ ] ── Mengonsumsi model, database, dan widget modular
     │         │
     │         ├── Mengambil cetak biru dari [ models/ ]
     │         ├── Mengambil data awal dari [ database/mock_data.dart ]
     │         └── Merakit UI menggunakan [ widgets/ ]
     │
     └──► [ widgets/ ] ── Komponen independen murni (Presentation Components)
```

* **`models/`**: Tidak bergantung pada siapa pun. Hanya mendefinisikan bentuk data.
* **`database/`**: Bergantung pada `models/` untuk membuat daftar objek dummy awal.
* **`widgets/`**: Hanya fokus pada presentasi visual. Berkomunikasi dengan layar induk melalui parameter konstruktor dan fungsi *callback*.
* **`screens/`**: Bertindak sebagai konduktor orkestra yang menghubungkan model, state, event pengguna, dan widget.
* **`main.dart`**: Menghubungkan semua layar ke dalam pohon aplikasi `MaterialApp`.

---

## 3. Katalog Layar (Screens) & Pemakaian Reusable Widgets

Setiap layar di `lib/screens/` tidak membuat elemen visual berulang dari nol, melainkan memanfaatkan koleksi komponen di `lib/widgets/`:

| Halaman (*Screen*) | Reusable Widget yang Digunakan | Peran dan Fungsi |
| :--- | :--- | :--- |
| **`DashboardScreen`** | `ScheduleCard` | Menampilkan ucapan salam, jam besar, kartu progres ibadah, dan daftar jadwal aktif. |
| **`ScheduleScreen`** | `ScheduleCard`, `EmptyStateView` | Menampilkan daftar jadwal ibadah. Menampilkan `EmptyStateView` jika jadwal kosong. |
| **`HistoryScreen`** | `HistoryCard`, `EmptyStateView` | Menampilkan riwayat pelaksanaan ibadah. |
| **`CreateScheduleScreen`** | `TimePickerCard`, `DaySelector`, `DescriptionCard`, `SettingTile`, `PrimaryButton` | Formulir lengkap penambahan jadwal baru dengan validasi input. |
| **`EditScheduleScreen`** | `TimePickerCard`, `DaySelector`, `DescriptionCard`, `SettingTile`, `PrimaryButton` | Formulir pengubahan jadwal yang sudah ada dengan data awal terisi. |
| **`DetailScheduleScreen`** | `DaySelector` *(Read-Only)*, `DescriptionCard` *(Display)*, `SettingTile` *(Display)*, `StatusBadge` | Menampilkan rincian jadwal terpilih serta opsi Edit dan Hapus. |
| **`DetailHistoryScreen`** | `StatusBadge` | Menampilkan catatan waktu seharusnya vs waktu terlaksana dari suatu riwayat. |

---

## 4. Sistem Navigasi (Tab Navigation vs Stack Navigation)

Aplikasi Nawaitu menerapkan **dua pola navigasi berbeda** yang bekerja secara harmonis:

```
                           [ MaterialApp ]
                                  │
                   ( initialRoute: AppRoutes.main )
                                  │
                                  ▼
                        [ MainNavigation ]
                    (Index-based Tab Navigation)
                    ┌─────────────┬─────────────┐
                    ▼             ▼             ▼
               [Dashboard]   [Schedule]     [History]
                                  │             │
                    Navigator.pushNamed(...)    │ Navigator.pushNamed(...)
                                  │             │
              ┌───────────────────┴──┐          ▼
              ▼                      ▼   [DetailHistoryScreen]
    [CreateScheduleScreen]  [DetailScheduleScreen]
                                     │
                             Navigator.pushNamed(...)
                                     │
                                     ▼
                           [EditScheduleScreen]
```

### A. Tab Navigation (Index-based Switching)
* **Pusat Pengatur:** `lib/screens/main_navigation.dart`
* **Cara Kerja:** Layar induk memiliki `BottomNavigationBar` dengan properti `currentIndex: _selectedIndex`.
* **Karakteristik:**
  - **Tanpa Push/Pop:** Perpindahan antara tab Beranda (Index 0), Jadwal (Index 1), dan Riwayat (Index 2) **tidak menumpuk layar baru**.
  - Mengubah tampilan cukup dengan memanggil `setState(() => _selectedIndex = index)`.

### B. Stack Navigation (Centralized Named Routes via Push-Pop)
* **Pusat Pengatur:** `lib/core/app_routes.dart` & tabel `routes: { ... }` di `lib/main.dart`.
* **Karakteristik:**
  - Bekerja seperti tumpukan piring (*Stack*).
  - **`Navigator.pushNamed(context, AppRoutes.tujuan, arguments: data)`**: Mendorong halaman baru ke atas tumpukan.
  - **`Navigator.pop(context, result)`**: Mencabut halaman teratas untuk kembali ke halaman sebelumnya sambil membawa data hasil.
* **Ekstraksi Argumen:**
  Halaman penerima mengekstrak data yang dikirim melalui `ModalRoute.of(context)?.settings.arguments` pada siklus hidup `didChangeDependencies()` atau `build()`.

---

## 5. Manajemen State (Stateful vs StatelessWidget & setState)

### Kategori Widget Berdasarkan State:
* **`StatelessWidget` (Komponen Statis / Pasif):**
  - Tidak memiliki memori internal yang berubah selama widget aktif.
  - **Diterapkan pada:** `DashboardScreen`, `DetailHistoryScreen`, dan **seluruh Reusable Widget** di `lib/widgets/` (`DaySelector`, `DescriptionCard`, `HistoryCard`, `PrimaryButton`, `SettingTile`, `StatusBadge`, `TimePickerCard`, `EmptyStateView`).
  - *Keuntungan:* Hemat penggunaan memori dan proses render sangat cepat.

* **`StatefulWidget` (Komponen Dinamis / Reaktif):**
  - Memiliki objek `State` terpisah untuk menyimpan data yang dapat berubah akibat aksi pengguna.
  - **Diterapkan pada:** `MainNavigation` (menyimpan tab aktif), `ScheduleScreen` (menyimpan list jadwal), `CreateScheduleScreen` (menyimpan input form), `EditScheduleScreen` (menyimpan perubahan), `DetailScheduleScreen` (menyimpan state hasil edit), `HistoryScreen`.

### Cara Kerja `setState()`:
Saat data variabel di dalam class `State` berubah, fungsi `setState(() { ... })` wajib dipanggil untuk memberi sinyal ke Flutter Engine agar menjalankan ulang method `build()` dan menggambar ulang bagian UI yang terpengaruh.

### Siklus Hidup (Lifecycle) yang Digunakan:
1. **`initState()`**: Berjalan 1 kali saat widget pertama kali dibuat (contoh: memuat list dari `mock_data.dart`).
2. **`didChangeDependencies()`**: Berjalan setelah konteks sistem siap (digunakan untuk mengekstrak data rute `ModalRoute.of(context)`).
3. **`build()`**: Menyusun pohon tampilan visual.
4. **`dispose()`**: Berjalan saat widget ditutup/dihancurkan untuk membersihkan resource memori (contoh: `_titleController.dispose()`).

---

## 6. Sinkronus vs Asinkronus (Async, Await, Future)

Flutter berjalan pada *Single Thread Event Loop*. Operasi yang membutuhkan waktu tunggu tidak boleh memblokir UI thread agar aplikasi tidak macet (*freeze/jank*).

### Penerapan Asinkronus di Proyek Nawaitu:
1. **Penguncian Orientasi Layar di `lib/main.dart`:**
   ```dart
   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     await SystemChrome.setPreferredOrientations([...]);
     runApp(const MyApp());
   }
   ```
   Menunggu sistem operasi selesai menerapkan penguncian orientasi sebelum widget utama dijalankan.

2. **Dialog Pemilihan Jam (`showTimePicker`) di `create_schedule_screen.dart` & `edit_schedule_screen.dart`:**
   ```dart
   Future<void> _pickTime() async {
     final TimeOfDay? picked = await showTimePicker(...);
     if (picked != null) setState(() => _selectedTime = picked);
   }
   ```
   Aplikasi menunggu pengguna selesai memutar jarum jam dan menekan "OK" tanpa membekukan antarmuka.

3. **Menunggu Hasil Navigasi Rute di `schedule_screen.dart` & `detail_schedule_screen.dart`:**
   ```dart
   final result = await Navigator.pushNamed(context, AppRoutes.createSchedule);
   ```
   Layar jadwal menunggu hingga pengguna selesai membuat jadwal baru dan menekan tombol simpan (`Navigator.pop(context, newSchedule)`).

---

## 7. Mutable vs Immutable Data

### A. Immutable (Kekal / Tidak Dapat Diubah Langsung)
* Model data (`ScheduleModel` dan `HistoryModel`) bersifat **Immutable**:
  - Seluruh properti dideklarasikan sebagai `final`.
  - Jika ingin mengubah suatu properti (misalnya mengubah status `isActive`), kita **tidak boleh** mengubah langsung `schedule.isActive = false`.
  - Sebagai gantinya, digunakan metode **`copyWith(...)`** untuk menduplikasi objek lama dengan atribut baru yang diinginkan:
    ```dart
    final updated = schedule.copyWith(isActive: false);
    ```

### B. Mutable (Dapat Berubah)
* Variabel state di dalam `StatefulWidget` bersifat **Mutable**:
  - Contoh: `List<ScheduleModel> _schedules` di `ScheduleScreen`.
  - List tersebut dapat ditambah (`.add()`), dihapus (`.removeAt()`), atau diperbarui elemennya di dalam blok `setState()`.

---

## 8. Peran Mock Data (Database Tiruan)

Berkas `lib/database/mock_data.dart` bertindak sebagai **Single Source of Truth sementara (In-Memory Database)** sebelum aplikasi diintegrasikan dengan database permanen (seperti SQLite, Hive, atau Firebase).

### Pertanyaan Kritis: Apakah data ini bisa diutak-atik langsung dalam aplikasi?
* **BISA (Secara Runtime / In-Memory):**
  Saat aplikasi berjalan, pengguna dapat menambah jadwal baru, mengedit nama/jam, menghapus jadwal, dan mengaktifkan/menonaktifkan alarm. UI akan merespons dan memperbarui data secara langsung.
* **Keterbatasan Saat Ini:**
  Karena disimpan di dalam memori RAM sementara, **data akan kembali ke kondisi awal (reset)** saat aplikasi di-restart ulang (*Hot Restart* / tutup aplikasi total), karena data belum ditulis ke penyimpanan permanen perangkat.

---

## 9. Enkapsulasi: Public vs Library-Private (Underscore `_`)

Bahasa pemrograman Dart tidak menggunakan kata kunci `public` atau `private`. Hak akses ditentukan sepenuhnya oleh ada tidaknya karakter garis bawah (**underscore `_`**) pada awal identifier:

| Bentuk Nama | Aksesibilitas | Penjelasan & Contoh di Proyek |
| :--- | :--- | :--- |
| **Tanpa `_`** | **Public** | Dapat di-`import` dan diakses oleh berkas mana pun di luar filenya. Contoh: `class ScheduleScreen`, `class AppRoutes`, `class ScheduleModel`. |
| **Awalan `_`** | **Library-Private** | **Hanya dapat diakses di dalam berkas `.dart` tempat ia ditulis.** File lain dilarang membaca atau memodifikasinya. Contoh: `class _ScheduleScreenState`, variabel `_schedules`, `_selectedDays`, fungsi `_saveSchedule()`. |

Enkapsulasi ini melindungi data internal widget agar tidak dimanipulasi secara tidak sah oleh komponen lain.

---

## 10. Penguncian Orientasi Layar (Portrait Lock)

Aplikasi Nawaitu didesain secara vertikal (kartu jadwal, jam besar, dan progress bar). Agar tata letak antarmuka tetap presisi dan tidak rusak akibat rotasi layar:
* Orientasi layar dikunci secara permanen pada level Flutter Engine di [`lib/main.dart`](file:///d:/ProgramFile/Code/nawaitu/lib/main.dart):
  ```dart
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  ```
* Didukung konfigurasi Android Native pada [`android/app/src/main/AndroidManifest.xml`](file:///d:/ProgramFile/Code/nawaitu/android/app/src/main/AndroidManifest.xml).

---

## 11. Panduan Menjalankan Aplikasi

```bash
# 1. Unduh seluruh dependensi Flutter
flutter pub get

# 2. Jalankan analisis kualitas kode statis (Pastikan 0 issues)
dart analyze

# 3. Jalankan automated widget tests
flutter test

# 4. Jalankan aplikasi pada perangkat/emulator yang terhubung
flutter run
```
