# TV-Debloat

Debloat Android TV / Google TV lewat HP Android (**Termux**) atau laptop, tanpa root.
Aplikasi bloatware & iklan bawaan cuma dimatikan (`disable-user`), bukan dihapus permanen, jadi **100% aman dan semua bisa dibalikin**.

## Fitur Utama
- **Tanpa Root & Aman:** Memakai `pm disable-user --user 0` dan otomatis memproteksi aplikasi inti (`launcher` utama, `YouTube`, `Netflix`, `Play Store`, `Chromecast`, `Live TV`, `Bluetooth`, dan `Voice Remote`).
- **Smart ADB Wait:** Menunggu otomatis sampai kamu selesai klik **Allow / Izinkan** di layar TV menggunakan remote (mendukung port `5555` maupun *Wireless Debugging Pairing Code* Android 11+).
- **UI Lebih Responsif:** Mempercepat animasi sistem ke `0.5x` dan membersihkan cache (`trim-caches`) agar TV RAM 1GB–2GB terasa jauh lebih enteng.
- **Full Restore:** Menyimpan log aplikasi yang dimatikan ke `~/tv-debloat-log.txt` tanpa duplikat untuk di-restore kapan saja.

## Cara Pakai (via Termux di HP)
1. Install **Termux** dari F-Droid (versi Play Store sudah usang).
2. Di TV: **Settings > Device Preferences > About** > klik **Build** 7x sampai muncul *"You are a developer"*.
3. Masuk ke **Settings > Device Preferences > Developer options** > nyalakan **USB debugging** (dan **Network / Wireless debugging** kalau ada).
4. Pastikan HP dan TV satu WiFi, lalu catat IP TV (**Settings > Network**).
5. Di Termux, tempel perintah ini:

```bash
curl -sLO https://raw.githubusercontent.com/DaddyUnikii/TV-Debloat/main/tv-debloat.sh && bash tv-debloat.sh
```

6. Masukkan IP TV, lalu pilih **Allow / Izinkan** (centang *Always allow*) di layar TV. Restart TV setelah selesai.

## Balikin Semua (Restore)
Kalau ada aplikasi yang ingin diaktifkan kembali seperti semula:

```bash
bash tv-debloat.sh restore
```

Netflix, YouTube, siaran TV, launcher utama, Play Store, Chromecast, dan voice remote tidak disentuh.
