# TV-Debloat

Debloat Android TV / Google TV lewat HP Android (Termux), tanpa laptop dan tanpa root.
Aplikasi cuma dimatikan (disable), bukan dihapus, jadi semua bisa dibalikin.

## Cara pakai
1. Install **Termux** dari F-Droid (versi Play Store sudah usang).
2. Di TV: Settings > Device Preferences > About > klik **Build** 7x sampai muncul "You are a developer".
3. Settings > Device Preferences > **Developer options** > nyalakan **USB debugging** (dan Network/Wireless debugging kalau ada).
4. Pastikan HP dan TV satu WiFi, catat IP TV (Settings > Network).
5. Di Termux, tempel:

```
curl -sLO https://raw.githubusercontent.com/DaddyUnikii/TV-Debloat/main/tv-debloat.sh && bash tv-debloat.sh
```

6. Masukkan IP TV, lalu pilih **Allow** di layar TV. Restart TV setelah selesai.

## Balikin semua
```
bash tv-debloat.sh restore
```

Netflix, YouTube, siaran TV, launcher, Play Store, Chromecast, dan voice remote tidak disentuh.
