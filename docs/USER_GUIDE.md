# Panduan Pengguna Alburdat Presisi

> **Panduan lengkap untuk menggunakan sistem Alburdat Presisi - Alat Tabur Pupuk IoT**

Dokumen ini menjelaskan cara menggunakan alat dan aplikasi Alburdat Presisi dari awal setup hingga operasional harian.

## 📋 Daftar Isi

1. [Apa itu Alburdat?](#apa-itu-alburdat)
2. [Komponen & Spesifikasi](#komponen--spesifikasi)
3. [Persiapan Awal](#persiapan-awal)
4. [Setup Hardware](#setup-hardware)
5. [Konfigurasi WiFi](#konfigurasi-wifi)
6. [Menggunakan Aplikasi](#menggunakan-aplikasi)
7. [Fitur-Fitur](#fitur-fitur)
8. [Troubleshooting](#troubleshooting)
9. [Tips & Tricks](#tips--tricks)
10. [FAQ](#faq)

---

## Apa itu Alburdat?

**Alburdat Presisi** adalah alat tabur pupuk presisi berbasis IoT yang dirancang khusus untuk petani modern. Dengan teknologi ESP32 dan aplikasi mobile/web, Anda dapat:

✅ **Kontrol dosis pupuk** dengan presisi (5-50 gram)
✅ **Monitor status real-time** dari smartphone/tablet/komputer
✅ **Dapatkan rekomendasi dosis** otomatis berdasarkan jenis tanaman dan umur
✅ **Kelola statistik penggunaan** pupuk untuk analisis
✅ **Operasi offline** - tombol fisik selalu tersedia

**Keuntungan**:

- 💰 Hemat pupuk hingga 40% dengan dosis tepat
- ⏱️ Hemat waktu - tidak perlu nakar manual
- 📊 Data terukur untuk evaluasi hasil panen
- 🔄 Fleksibel - kontrol manual atau otomatis
- 🌐 Smart - rekomendasi berbasis AI

---

## Komponen & Spesifikasi

### Hardware

```
┌─────────────────────────────────────────┐
│         Alburdat Device                 │
├─────────────────────────────────────────┤
│                                         │
│    ┌─────────────────────────────┐    │
│    │ OLED Display (128x64 pixel) │    │
│    │ Tampil status & dosis       │    │
│    └─────────────────────────────┘    │
│                                         │
│    ┌──────────────┐ ┌──────────────┐   │
│    │  Btn +5g     │ │ Btn Trigger  │   │
│    │  (Increment) │ │ (Dispense)   │   │
│    └──────────────┘ └──────────────┘   │
│                                         │
│    ┌──────────────────────────────┐   │
│    │  Motor DC + Hopper Pupuk     │   │
│    │  (Dispense mechanism)        │   │
│    └──────────────────────────────┘   │
│                                         │
│    ┌──────────────────────────────┐   │
│    │  ESP32 Microcontroller       │   │
│    │  WiFi + MQTT Client          │   │
│    └──────────────────────────────┘   │
└─────────────────────────────────────────┘
```

### Spesifikasi Teknis

| Item                 | Spesifikasi               |
| -------------------- | ------------------------- |
| **Dosis Range**      | 5 - 50 gram               |
| **Resolusi**         | 5 gram per step           |
| **Kecepatan**        | ~3 detik per 5 gram       |
| **Koneksi**          | WiFi 2.4GHz 802.11b/g/n   |
| **Komunikasi**       | MQTT over TCP (port 1883) |
| **Power**            | DC 5V, 2A (micro USB)     |
| **Display**          | OLED 128x64 pixel         |
| **Button**           | 2 x push button           |
| **Kapasitas Hopper** | ~2-3 kg pupuk             |

---

## Persiapan Awal

Sebelum menggunakan alat, siapkan:

### Barang yang Diperlukan

- ✅ Alburdat Device (sudah dikalibrasi)
- ✅ Power adapter micro USB (5V, 2A)
- ✅ Smartphone/Tablet dengan Android/iOS
- ✅ Koneksi WiFi yang stabil
- ✅ Pupuk halus/butiran kecil (tidak gumpal)
- ✅ Hotspot/Mobile WiFi (opsional, untuk area tanpa WiFi)

### Persiapan Lokasi

1. **Pilih tempat terbuka** dengan sinyal WiFi/mobile yang baik
2. **Jaga perangkat tetap kering** (tidak terkena hujan langsung)
3. **Ventilasi cukup** untuk suhu operasional normal (0-40°C)
4. **Letakkan stabil** - hindari getaran berlebihan
5. **Dekat dengan hopper pengisian pupuk** untuk kemudahan refill

---

## Setup Hardware

### 1. Unboxing & Inspeksi

Saat menerima Alburdat Device:

1. Buka kemasan dengan hati-hati
2. Periksa kondisi fisik (cek untuk kerusakan)
3. Verifikasi semua komponen:
   - ✅ Main device
   - ✅ Power adapter
   - ✅ Kabel micro USB
   - ✅ Dokumentasi

### 2. Isi Hopper Pupuk

```
1. Buka cover hopper (di bagian atas)
2. Isi dengan pupuk halus/butiran (max ~2-3 kg)
3. Jangan pack/padatkan pupuk terlalu keras
4. Tutup cover kembali
5. Pastikan tidak ada kebocoran
```

**⚠️ Penting**: Gunakan pupuk dengan tekstur halus atau butiran kecil. Pupuk kasar/gumpal dapat menyebabkan **macet motor**.

### 3. Hubungkan Power

```
1. Colokkan adapter power ke outlet
2. Hubungkan kabel micro USB ke device
3. Device akan mulai boot (tunggu 2-3 detik)
4. OLED akan menyala menampilkan:
```

Alburdat Presisi
Initializing...

```
5. Tunggu hingga muncul status utama
```

### 4. Cara Kerja Fisik

**OLED Display** menampilkan:

```
┌──────────────────────────────┐
│ Status: SIAP                 │  (SIAP / MEMUPUK / ERROR)
│ WiFi: ✓  MQTT: ✓             │  (Koneksi status)
│ Dosis: 10.0 g                │  (Dosis yang diset)
│ Total: 150.5 g │ Sesi: 15    │  (Statistik)
└──────────────────────────────┘
```

**Tombol**:

| Tombol          | Aksi            | Hasil                                  |
| --------------- | --------------- | -------------------------------------- |
| **Btn +5g**     | Tekan 1x        | Dosis naik 5g (loop: 5→10→15→...→50→5) |
| **Btn Trigger** | Tekan & tahan   | Motor aktif dispense (~3s per 5g)      |
| **Keduanya**    | Tekan bersamaan | Reset (firmware dependent)             |

**Workflow Operasional**:

```
┌──────────────┐
│ SIAP         │  ← Device ready
└──────┬───────┘
       │
       ├─ Tekan Btn +5g (repeat) ─→ Set dosis
       │
       └─ Tekan Btn Trigger ──→ Mulai dispense
              │
              ├─ Motor aktif "MEMUPUK..."
              │
              ├─ Tunggu ~3s per 5g (tergantuk dosis)
              │
              └─ Selesai "SELESAI!"
                 │
                 └─ Kembali "SIAP" (3s kemudian)
```

---

## Konfigurasi WiFi

### Pertama Kali Setup

Saat first boot, device akan membuat hotspot WiFi:

1. **Cari hotspot WiFi**:
   - Name: `ALBURDAT_CONFIG`
   - Password: `petanisukses`

2. **Hubungkan dari smartphone**:
   - Buka WiFi Settings
   - Pilih `ALBURDAT_CONFIG`
   - Masuk password: `petanisukses`
   - Tunggu 3-5 detik

3. **Buka browser**:
   - Akses: `http://192.168.4.1`
   - Atau `http://alburdat.local` (jika device support mDNS)

4. **Config WiFi rumah**:
   - Pilih SSID WiFi rumah Anda dari list
   - Masuk password WiFi rumah
   - Klik "Save"

5. **Device restart** dan connect ke WiFi rumah

6. **OLED menampilkan**:
   ```
   WiFi: ✓
   MQTT: ✓ (setelah 5-10 detik)
   ```

### Reset WiFi (jika diperlukan)

**Dari tombol fisik**:

```
1. Tekan Btn +5g dan Btn Trigger secara bersamaan
2. Tahan 5 detik sampai OLED berubah
3. Device akan kembali ke mode "ALBURDAT_CONFIG"
4. Ulangi langkah 1-6 di atas
```

**Dari aplikasi**:

```
1. Buka app → Tab "WiFi"
2. Klik "Reset WiFi"
3. Device akan restart
4. Connect ke hotspot dan reconfigure
```

---

## Menggunakan Aplikasi

### Download & Install

**Option 1: Download dari App Store**

- iOS: App Store → Cari "Alburdat Presisi"
- Android: Google Play Store → Cari "Alburdat Presisi"
- Install dan buka

**Option 2: Download APK (Android)**

```
1. Download file .apk dari <link>
2. Arahkan ke file → tap → Install
3. Izinkan instalasi dari "Unknown Sources" jika diminta
```

**Option 3: Akses via Web**

- Buka browser → https://alburdat.web.app
- Atau jalankan lokal: `flutter run -d chrome`

### Launching untuk Pertama Kali

```
1. Buka aplikasi Alburdat Presisi
2. Tunggu splash screen (2-3 detik)
3. App akan otomatis connect ke MQTT broker
4. Tunggu hingga status device muncul
5. Jika connected, device status akan ditampilkan
```

**Indikator Koneksi**:

- 🟢 **Hijau**: MQTT connected & device online
- 🟠 **Orange**: WiFi ada tapi MQTT disconnect
- 🔴 **Merah**: Tidak terhubung

### Navigasi Tab

App terdiri dari 6 tab utama:

```
┌─────┬─────┬──────┬────────┬─────┬──────┐
│Home │Reko │Manual│Statistik│WiFi │Info  │
└─────┴─────┴──────┴────────┴─────┴──────┘
```

---

## Fitur-Fitur

### 1. Home / Dashboard

**Tampilan**:

```
┌─────────────────────────────┐
│      DASHBOARD              │
├─────────────────────────────┤
│ Device Status:              │
│  Dosis: 15.0 g ━━━●━━       │
│  Motor: SIAP ✓               │
│                              │
│ Statistik Hari Ini:          │
│  Total: 150.5 g              │
│  Sesi: 15 kali               │
│  Rata-rata: 10.0 g/sesi      │
│                              │
│  [Trigger Manual]            │
│  [Reset Statistik]           │
└─────────────────────────────┘
```

**Fitur**:

- 👀 Monitor dosis & status motor real-time
- 📊 Lihat statistik harian
- ⚙️ Trigger manual dispense (jika diperlukan)
- 🔄 Reset statistik harian

**Cara Pakai**:

1. Buka tab "Home"
2. Lihat status device real-time
3. Geser slider untuk ubah dosis (jika diinginkan)
4. Tap "Trigger" untuk dispense manual
5. Tap "Reset" untuk clear statistik harian

### 2. Rekomendasi

**Tampilan**:

```
┌─────────────────────────────┐
│     REKOMENDASI DOSIS       │
├─────────────────────────────┤
│                              │
│ Pilih Komoditas:             │
│ ┌─────────────────────────┐  │
│ │ [Padi]   [Jagung]       │  │
│ │ [Cabai]  [Bawang]      │  │
│ │ [Tomat]  [Timun]       │  │
│ └─────────────────────────┘  │
│                              │
│ HST (Hari Setelah Tanam):    │
│ ┌──────────────────────────┴─┐
│ │ Input: _____ (0-150)       │
│ └──────────────────────────┬─┘
│                              │
│ [Hitung Rekomendasi]         │
│                              │
│ Hasil:                       │
│ ✓ Rekomendasi: 12.5 g        │
│ [Set Dosis ke Device]        │
│                              │
└─────────────────────────────┘
```

**Cara Pakai**:

1. **Pilih komoditas**:
   - Tap komoditas yang Anda tanam (Padi, Jagung, dll)

2. **Input HST**:
   - Masuk umur tanaman dalam hari (misal: 30 untuk 30 HST)

3. **Hitung**:
   - Tap "Hitung Rekomendasi"
   - Aplikasi akan memberikan dosis optimal

4. **Terapkan**:
   - Tap "Set Dosis ke Device" untuk auto-set dosis
   - Device akan menerima command dan update dosis

**Knowledge Base** (contoh):

| Komoditas | HST Range | Rekomendasi |
| --------- | --------- | ----------- |
| Padi      | 0-20      | 5 gram      |
|           | 21-40     | 10 gram     |
|           | 41-60     | 12 gram     |
| Jagung    | 0-30      | 8 gram      |
|           | 31-60     | 15 gram     |
|           | 61-90     | 12 gram     |
| Cabai     | 0-25      | 5 gram      |
|           | 26-50     | 12 gram     |
|           | 51-100    | 15 gram     |

### 3. Manual

**Tampilan**:

```
┌─────────────────────────────┐
│     KONTROL MANUAL          │
├─────────────────────────────┤
│                              │
│ Dosis Saat Ini: 15.0 g       │
│                              │
│ Slider Kontrol:              │
│ 5g ──●────────── 50g         │
│                              │
│ Input Manual:                │
│ ┌──────────────────────────┐ │
│ │ Dosis: _______ gram      │ │
│ └──────────────────────────┘ │
│                              │
│ [- 5g]  [+ 5g]  [Set]        │
│                              │
│ [Trigger Dispense]           │
│                              │
└─────────────────────────────┘
```

**Cara Pakai**:

1. **Geser slider**:
   - Drag slider untuk set dosis (5-50g)
   - Atau input manual di textbox

2. **Konfirmasi**:
   - Tap "Set" untuk mengirim ke device

3. **Trigger**:
   - Tap "Trigger Dispense" untuk mulai dispense
   - Device akan mulai motor sesuai dosis

**Tips**:

- Ubah dosis sebelum trigger, bukan saat motor aktif
- Untuk dosis presisi, gunakan input manual bukan slider

### 4. Statistik

**Tampilan**:

```
┌─────────────────────────────┐
│     STATISTIK PENGGUNAAN    │
├─────────────────────────────┤
│ Periode: ________________   │
│          [Hari] [Bulan] [Tahun]
│                              │
│ 📊 Chart Penggunaan Pupuk:   │
│   |                          │
│ g |    ╱╲      ╱╲            │
│ a |   ╱  ╲    ╱  ╲           │
│ m |  ╱     ╲  ╱              │
│ . |                          │
│   └─┴─────────────────       │
│     H S  K  S  M  J  S       │
│       u  a  n  n  a  a       │
│       1  2  3  4  5  6       │
│                              │
│ Total Bulan Ini: 1500.5 g    │
│ Rata-rata/Hari: 50 g         │
│ Total Sesi: 150 kali         │
│                              │
│ [Export Data] [Reset All]    │
│                              │
└─────────────────────────────┘
```

**Cara Pakai**:

1. **Pilih periode**:
   - Tap "Hari", "Bulan", atau "Tahun"

2. **Lihat chart**:
   - Graph menampilkan trend penggunaan pupuk

3. **Analisa**:
   - Total pupuk dalam periode
   - Rata-rata per hari/sesi

4. **Export** (opsional):
   - Tap "Export Data" → simpan CSV untuk analisis lanjutan

5. **Reset**:
   - Tap "Reset All" untuk clear SEMUA statistik
   - ⚠️ **Hati-hati**: Tidak bisa di-undo!

### 5. WiFi Settings

**Tampilan**:

```
┌─────────────────────────────┐
│     CONFIGURASI WiFi        │
├─────────────────────────────┤
│                              │
│ Status Koneksi:             │
│ WiFi: alburdat_home ✓        │
│ MQTT: broker.emqx.io ✓       │
│ Device: Online ✓             │
│                              │
│ Informasi:                   │
│ IP Address: 192.168.1.100    │
│ Signal: -45 dBm (Excellent)  │
│ Uptime: 2 hari 3 jam         │
│                              │
│ [Change WiFi Network]        │
│ [Reset WiFi]                 │
│                              │
└─────────────────────────────┘
```

**Cara Pakai**:

1. **Lihat status**:
   - Cek koneksi WiFi & MQTT

2. **Ganti WiFi**:
   - Tap "Change WiFi Network"
   - Device akan restart dan enter config mode
   - Connect ke `ALBURDAT_CONFIG` dan reconfigure

3. **Reset WiFi** (jika ada masalah):
   - Tap "Reset WiFi"
   - Device hardness reset ke factory config

### 6. Info

**Tampilan**:

```
┌─────────────────────────────┐
│       INFORMASI APLIKASI    │
├─────────────────────────────┤
│                              │
│ Alburdat Presisi v1.0.1      │
│ Sistem IoT Tabur Pupuk       │
│                              │
│ Device Info:                 │
│ Model: ESP32 DevKit          │
│ Firmware: v2.1.0             │
│ MQTT Broker: broker.emqx.io  │
│ Last Update: 2 jam lalu      │
│                              │
│ Status MQTT:                 │
│ Connected: ✓                 │
│ Subscribed: ✓                │
│ Pub/Sub Count: 15,234        │
│                              │
│ [Copy Device ID] [About]     │
│ [Check Updates] [Feedback]   │
│                              │
└─────────────────────────────┘
```

**Fitur**:

- 📱 Informasi app version
- 🔧 Device firmware info
- 🌐 Status MQTT connection
- 📊 Statistics pub/sub
- 🔗 Copy device ID untuk troubleshooting

---

## Troubleshooting

### Problem: Aplikasi tidak bisa connect ke Device

**Gejala**:

- Status: "Offline" (merah)
- Tidak ada update dosis/status

**Solusi**:

1. **Cek WiFi**:
   - Device dan smartphone harus di WiFi yang sama
   - Cek sinyal WiFi stabil
   - Try reconnect: Airplane mode on/off

2. **Cek MQTT Broker**:

   ```
   - Buka app Info tab
   - Verifikasi broker address: broker.emqx.io:8083
   - Try alternate broker (EMQX, HiveMQ) jika default down
   ```

3. **Restart device**:

   ```
   - Cabut power adapter
   - Tunggu 5 detik
   - Plug kembali
   - Tunggu MQTT connected (5-10 detik)
   ```

4. **Reset WiFi configuration**:
   ```
   - Dari app: WiFi tab → "Reset WiFi"
   - Atau: Tekan Btn +5g + Btn Trigger 5 detik
   - Reconfigure WiFi
   ```

### Problem: Dosis tidak berubah saat digeser slider

**Gejala**:

- Slider bergerak tapi device tidak update

**Solusi**:

1. **Cek koneksi MQTT**:
   - Pastikan "MQTT: ✓" muncul di app

2. **Tap "Set" button**:
   - Jangan lupa confirm dengan mengklik "Set"

3. **Manual input**:
   - Gunakan input textbox untuk presisi
   - Tap "Set"

4. **Restart app**:
   ```
   - Close app sepenuhnya
   - Buka kembali
   - Wait untuk MQTT connect
   ```

### Problem: Motor tidak berputar saat trigger

**Gejala**:

- MQTT connected tapi motor tidak aktif
- OLED tetap "SIAP"

**Solusi**:

1. **Cek hopper pupuk**:
   - Hopper kosong? Isi pupuk
   - Pupuk gumpal/macet? Lepas hopper, bersihkan

2. **Test tombol fisik**:
   - Tekan Btn Trigger fisik di device
   - Jika ini berhasil, masalah pada command MQTT

3. **Check firmware**:
   - Device mungkin perlu firmware update
   - Contact support untuk latest firmware

4. **Power reset**:
   - Cabut power, tunggu 10 detik, plug kembali
   - Try trigger lagi

### Problem: WiFi sering disconnect

**Gejala**:

- WiFi status on/off berubah-ubah
- MQTT sering "Offline"

**Solusi**:

1. **Cek sinyal WiFi**:
   - Device mungkin terlalu jauh dari router
   - Pindahkan device lebih dekat ke router
   - Atau upgrade WiFi router ke band dual 5GHz

2. **Cek interference**:
   - Jauh dari microwave, cordless phone
   - Hindari area dengan banyak WiFi neighbor (misal apartement)

3. **Fix WiFi settings**:
   - WiFi tab → "Change WiFi Network"
   - Pilih SSID yang sama tapi dengan signal lebih kuat
   - Input password dengan benar

4. **Factory reset**:
   - Last resort: hold Btn trigger 10 detik
   - Device akan reset factory settings
   - Reconfigure dari awal

### Problem: Statistik tidak terupdate

**Gejala**:

- Total gram dan sesi tidak bertambah setelah trigger

**Solusi**:

1. **Trigger selesai?**:
   - Wait sampai "SELESAI" muncul
   - Data akan sync 2-3 detik kemudian

2. **Force refresh**:
   - Pull-to-refresh (swipe down) di Statistics tab
   - Atau buka tab lain, kembali ke Statistics

3. **Restart app**:
   - Close dan reopen app
   - Data seharusnya terupdate

4. **Check device EEPROM**:
   - Firmware mungkin tidak save ke storage
   - Device restart = statistik reset (belum fix)
   - Contact support

### Problem: Hopper macet / motor lambat

**Gejala**:

- Motor berputar tapi pupuk tidak keluar
- Atau motor sangat lambat

**Solusi**:

1. **Bersihkan hopper**:

   ```
   1. Lepas cover hopper
   2. Lepas hopper dari device
   3. Keluarkan semua pupuk
   4. Bersihkan sisa pupuk dengan kuas kering
   5. Cek kaliber lubang dispense tidak tersumbat
   6. Pasang kembali
   7. Isi pupuk segar
   ```

2. **Gunakan pupuk halus**:
   - Ganti ke pupuk butiran lebih kecil/halus
   - Hindari pupuk kasar atau gumpal

3. **Adjust kalibration** (advanced):
   - Edit `waktuPer5Gram` di firmware
   - Increase nilai jika motor too fast
   - Decrease nilai jika motor too slow
   - Default: 3000 ms = 3 detik per 5 gram

### Problem: Aplikasi crash / force close

**Gejala**:

- App tiba-tiba tertutup
- Error message muncul

**Solusi**:

1. **Update app**:
   - Check App Store / Play Store untuk update
   - Install latest version

2. **Clear cache**:

   ```
   - Go to Settings → Apps → Alburdat
   - Tap "Storage" → "Clear Cache"
   - Restart app
   ```

3. **Reinstall app**:

   ```
   - Uninstall app sepenuhnya
   - Restart phone
   - Reinstall dari App Store / Play Store
   ```

4. **Check phone RAM**:
   - Close background apps
   - Free up RAM sebelum buka app

---

## Tips & Tricks

### ⚡ Performa Optimal

1. **Posisi device**:
   - Dekat dengan WiFi router (jarak < 5 meter)
   - Tidak ada obstacle berat (tembok besi, metal)

2. **Update firmware**:
   - Check update device firmware secara berkala
   - Firmware baru = performa lebih baik

3. **Bersihkan hopper** setiap minggu:
   - Hindari pupuk berceceran
   - Motor lancar = akurasi lebih tinggi

4. **Kalibräsi ulang** setiap bulan:
   ```
   - Test: set 10g, trigger, ukur dengan timbangan
   - Jika hasil ≠ 10g, adjust waktuPer5Gram di firmware
   ```

### 📊 Maksimalkan Data

1. **Export statistik** monthly:
   - Statistik tab → "Export Data"
   - Simpan CSV untuk analisis jangka panjang

2. **Bandingkan dengan hasil panen**:
   - Catatan: dosis optimal per komoditas
   - Improve rekomendasi untuk musim depan

3. **Track ROI**:
   - Hitung penghematan pupuk vs hasil panen
   - Justifikasi investasi Alburdat

### 🔒 Keamanan

1. **Cek WiFi password**:
   - Gunakan password WiFi yang kuat
   - Minimal 12 karakter, mix huruf/angka/simbol

2. **MQTT broker security**:
   - Jika using cloud broker (EMQX, HiveMQ)
   - Enable username/password authentication
   - Update security rules regularly

3. **Backup data**:
   - Export statistik secara teratur
   - Simpan csv file lokal

---

## FAQ

### **Q: Apakah device perlu internet selalu?**

**A**: Browser dalam WiFi yang sama. Untuk cloud access (monitor dari jauh), memerlukan internet.

---

### **Q: Berapa lama battery device?**

**A**: Device menggunakan power adapter DC 5V, bukan battery. Harus selalu connected ke power.

---

### **Q: Bisa ganti broker MQTT?**

**A**: Ya, ubah address di app settings. Tapi device harus juga diprogram ulang (edit firmware).

---

### **Q: Bagaimana jika hopper kosong?**

**A**: Motor akan berputar tapi tidak ada pupuk keluar. Set timer untuk refill, atau check visually sebelum trigger.

---

### **Q: Apakah bisa digunakan di area tanpa WiFi?**

**A**: Ya, gunakan:

- Tombol fisik di device (selalu berfungsi)
- Mobile hotspot dari smartphone
- WiFi portabel (power bank WiFi)

---

### **Q: Bagaimana cara kalibrasi akurasi dosis?**

**A**:

```
1. Set dosis 10g di app
2. Trigger dispense
3. Timbang hasil dengan timbangan digital
4. Jika tidak tepat 10g:
   - Edit waktuPer5Gram di firmware
   - Upload firmware ulang
   - Test kembali
```

---

### **Q: Aplikasi bisa offline?**

**A**: Tidak - app selalu memerlukan MQTT connection. Tapi device fisik selalu bisa digunakan via tombol (offline mode).

---

### **Q: Apakah bisa control dari smartphone lain?**

**A**: Ya! Cukup install app & connect WiFi yang sama. Multiple smartphone bisa connect ke 1 device.

---

### **Q: Berapa cost per bulan?**

**A**: Hanya cost WiFi/internet rumah. Cloud MQTT broker (broker.emqx.io) gratis untuk personal use.

---

**Pertanyaan Lainnya?** Hubungi support@alburdat.io atau buat issue di GitHub repository.

---

**Last Updated**: 2024
**Version**: 1.0.1
**Language**: Bahasa Indonesia
**Support**: Email / GitHub / WhatsApp

---
