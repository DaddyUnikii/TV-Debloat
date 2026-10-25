#!/data/data/com.termux/files/usr/bin/bash
# TV Debloat via Termux - aman & bisa dibalikin (pakai disable, bukan hapus)
# Jalankan: bash tv-debloat.sh        |  Balikin: bash tv-debloat.sh restore

LOG="$HOME/tv-debloat-log.txt"

if ! command -v adb >/dev/null 2>&1; then
  echo ">> Install adb dulu..."
  pkg update -y && pkg install -y android-tools || { echo "Gagal install adb"; exit 1; }
fi

connect_tv() {
  if adb devices | grep -qE "\sdevice$"; then return 0; fi
  echo ""
  echo "Masukkan IP TV (lihat di TV: Settings > Network > status jaringan), contoh 192.168.1.20"
  read -rp "IP TV: " IP
  echo ">> Nyambung ke $IP:5555 ... cek layar TV, pilih 'Allow / Izinkan' (centang 'Always allow')"
  adb connect "$IP:5555"
  sleep 4
  if ! adb devices | grep -qE "\sdevice$"; then
    echo ""
    echo "Belum nyambung. Kalau TV punya 'Wireless debugging' dengan kode pairing:"
    echo "buka menu itu di TV > 'Pair device with pairing code', lalu isi di sini."
    read -rp "IP:PORT pairing (contoh 192.168.1.20:37000, Enter untuk batal): " PAIR
    [ -z "$PAIR" ] && { echo "Batal. Pastikan USB debugging ON & HP-TV satu WiFi."; exit 1; }
    read -rp "Kode pairing 6 digit: " CODE
    adb pair "$PAIR" "$CODE"
    read -rp "IP:PORT yang tampil di layar Wireless debugging (bukan port pairing): " CONN
    adb connect "$CONN"; sleep 3
    adb devices | grep -qE "\sdevice$" || { echo "Masih gagal nyambung."; exit 1; }
  fi
  echo ">> Tersambung ke TV!"
}

if [ "$1" = "restore" ]; then
  connect_tv
  [ -f "$LOG" ] || { echo "Log nggak ada, nggak ada yang perlu dibalikin."; exit 0; }
  while read -r p; do
    [ -z "$p" ] && continue
    adb shell pm enable "$p" >/dev/null 2>&1 || adb shell cmd package install-existing "$p" >/dev/null 2>&1
    echo "Dibalikin: $p"
  done < "$LOG"
  adb shell settings put global window_animation_scale 1
  adb shell settings put global transition_animation_scale 1
  adb shell settings put global animator_duration_scale 1
  echo ">> Selesai. Restart TV ya."
  exit 0
fi

connect_tv

# Aplikasi bawaan yang aman dimatikan (cuma dimatikan kalau ada di TV)
BLOAT="
com.google.android.videos
com.google.android.music
com.google.android.youtube.tvmusic
com.google.android.youtube.tvkids
com.google.android.play.games
com.google.android.feedback
com.google.android.tvtutorials
com.google.android.backdrop
com.google.android.apps.tv.dreamx
com.android.dreams.basic
com.android.printspooler
com.android.bips
com.android.bookmarkprovider
com.android.wallpaperbackup
com.android.gallery3d
com.android.traceur
com.google.android.marvin.talkback
com.google.android.apps.tv.launcherx.coldstart
com.google.android.tv.bugreportsender
com.google.android.apps.tv.tvappdeals
com.google.android.leanbacklauncher.recommendations
com.facebook.katana
com.facebook.system
com.facebook.appmanager
com.amazon.amazonvideo.livingroom
com.spotify.tv.android
"

# Pengaman: apa pun yang cocok pola ini TIDAK akan disentuh
PROTECT="netflix|youtube.tv$|com.google.android.youtube.tv|launcher|settings|vending|gms|gsf|katniss|mediashell|inputmethod|tvinput|livetv|tv.input|systemui|setupwraparound|remote|bluetooth|packageinstaller|webview|tvsettings|providers"

INSTALLED=$(adb shell pm list packages | tr -d '\r' | sed 's/package://')

echo ""
read -rp "Prime Video & Spotify ikut dimatikan? (y/n, default n): " KILLAPPS
: > "$LOG.tmp"
for p in $BLOAT; do
  if [ "$KILLAPPS" != "y" ] && echo "$p" | grep -qE "amazonvideo|spotify"; then continue; fi
  echo "$p" | grep -qE "$PROTECT" && continue
  if echo "$INSTALLED" | grep -qx "$p"; then
    if adb shell pm disable-user --user 0 "$p" 2>&1 | grep -qi "disabled"; then
      echo "Dimatikan: $p"; echo "$p" >> "$LOG.tmp"
    fi
  fi
done
cat "$LOG.tmp" >> "$LOG" 2>/dev/null; rm -f "$LOG.tmp"

# Animasi lebih cepat (bikin menu terasa ngebut)
adb shell settings put global window_animation_scale 0.5
adb shell settings put global transition_animation_scale 0.5
adb shell settings put global animator_duration_scale 0.5

echo ""
echo ">> Aplikasi bawaan merek TV (cuma ditampilkan, TIDAK disentuh):"
echo "$INSTALLED" | grep -iE "toshiba|tpv|skyworth|hisense|mediatek|mstar|realtek|vidaa" || echo "(nggak ada)"
echo ""
echo ">> Beres! Restart TV biar kerasa. Kalau ada yang aneh: bash tv-debloat.sh restore"
