# 📸 MZ Photobooth

Aplikasi photobooth digital modern berbasis Flutter yang dirancang untuk memberikan pengalaman foto estetik, praktis, dan menyenangkan. Pengguna dapat berfoto secara langsung atau mengunggah foto, memilih berbagai desain frame kreatif, menerapkan filter warna, dan menyimpan hasilnya ke perangkat.

---

## ✨ Fitur Utama

- 📷 **Kamera Interaktif & Upload Foto**:
  - Ambil foto langsung melalui kamera (kamera depan / belakang) dengan timer countdown (3 detik) dan efek flash.
  - Opsi unggah (*upload*) foto langsung dari galeri perangkat.
- 🖼️ **Koleksi Frame Beragam**:
  - Pilihan frame menarik dengan berbagai format:
    - **Frame 1 Foto**: Format single-shot klasik.
    - **Frame 2 Foto**: Format strip vertikal 2 pose.
    - **Frame 3 Foto**: Format strip 3 pose favorit.
    - **Frame 4 Foto**: Format 2x2 grid photobooth.
- 🎨 **Filter & Efek Estetik**:
  - Pilihan preset filter warna (Original, Cool Tone, Hitam Putih / Studio Monokrom, Analog 35mm, dll.).
- 🔄 **Review & Foto Ulang (Retake)**:
  - Kemudahan meninjau hasil pose pada setiap slot foto sebelum dicetak ke frame akhir.
- 💾 **Simpan & Unduh Otomatis**:
  - Simpan langsung ke galeri foto (Android/iOS) atau download instan dalam format gambar (Web).
- 🌐 **Multi-Platform Ready**:
  - Dioptimalkan untuk berjalan di platform **Android** dan **Web Browser**.

---

## 🛠️ Teknologi & Dependensi

- **Framework**: [Flutter](https://flutter.dev/) (SDK Dart `^3.13.4`)
- **Desain & UI**: Material 3, Google Fonts (*Plus Jakarta Sans*)
- **Paket Utama**:
  - `camera`: Akses kamera native perangkat
  - `image_picker`: Pemilihan gambar dari penyimpanan/galeri
  - `gal`: Penyimpanan gambar langsung ke galeri galeri ponsel
  - `path_provider`: Manajemen path direktori penyimpanan lokal
  - `device_preview`: Pengujian tampilan responsif berbagai resolusi

---

## 📁 Struktur Direktori

```text
mzphotobooth/
├── assets/
│   ├── example/          # Contoh gambar preview
│   ├── frame/            # Aset template frame (1, 2, 3, dan 4 foto)
│   └── logo/             # Logo & ikon aplikasi
├── lib/
│   ├── screens/
│   │   ├── home_screen.dart            # Halaman awal / landing
│   │   ├── frame_selection_screen.dart # Pemilihan frame & kategori
│   │   └── photo_screen.dart           # Sesi foto, filter, review & export
│   ├── theme/
│   │   └── app_colors.dart             # Palet warna & tema
│   ├── utils/
│   │   ├── camera_helper_*.dart        # Handler kamera lintas platform (Web & Mobile)
│   │   ├── file_saver_*.dart           # Handler simpan / download gambar
│   │   └── image_picker_helper_*.dart  # Handler picker file gambar
│   └── main.dart                       # Entry point aplikasi
└── pubspec.yaml
```

---

## 🚀 Cara Menjalankan Proyek

### Prasyarat
- Pastikan sudah menginstal [Flutter SDK](https://docs.flutter.dev/get-started/install) versi terbaru.
- Perangkat fisik Android / Emulator, atau Google Chrome untuk pengujian Web.

### Langkah Instalasi

1. **Clone repository ini** (atau unduh zip proyek):
   ```bash
   git clone https://github.com/mizanyf/mzphotobooth.git
   cd mzphotobooth
   ```

2. **Pasang dependensi**:
   ```bash
   flutter pub get
   ```

3. **Jalankan aplikasi**:
   - Untuk Web (Chrome):
     ```bash
     flutter run -d chrome
     ```
   - Untuk Android:
     ```bash
     flutter run -d <device-id>
     ```

---

## 📦 Build Aplikasi

- **Build APK (Android)**:
  ```bash
  flutter build apk --release
  ```
- **Build Web**:
  ```bash
  flutter build web --release
  ```

---

## 📄 Lisensi

Proyek ini dibuat untuk keperluan portofolio / pribadi. Bebas digunakan dan dimodifikasi sesuai kebutuhan.
