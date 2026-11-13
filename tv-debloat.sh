#!/usr/bin/env bash
# TV Debloat via Termux / Linux / macOS - aman & bisa dibalikin (pakai disable, bukan hapus)
# Jalankan: bash tv-debloat.sh        |  Balikin: bash tv-debloat.sh restore

LOG="$HOME/tv-debloat-log.txt"

if ! command -v adb >/dev/null 2>&1; then
  if command -v pkg >/dev/null 2>&1; then
    echo ">> Install adb dulu via Termux..."
    pkg update -y && pkg install -y android-tools || { echo "Gagal install adb"; exit 1; }
  else
    echo ">> 'adb' belum terinstall. Silakan install android-tools / adb terlebih dahulu."
    exit 1
  fi
fi

is_connected() {
  adb devices | grep -qE "[[:space:]]device$"
}

is_unauthorized() {
  adb devices | grep -qE "[[:space:]]unauthorized"
}

wait_for_auth() {
  local tries=${1:-15}
  local i=0
  while [ "$i" -lt "$tries" ]; do
    if is_connected; then
      return 0
    fi
    if is_unauthorized; then
      echo "   ... menunggu kamu klik 'Allow / Izinkan' di layar TV ($((tries - i))s)..."
    elif [ "$i" -ge 3 ]; then
      # Port tidak merespon / bukan menunggu otorisasi
      return 1
    fi
    sleep 2
    i=$((i + 1))
  done
  is_connected
}

connect_tv() {
  if is_connected; then return 0; fi

  if is_unauthorized; then
    echo ">> TV terdeteksi tapi belum diizinkan. Cek layar TV, centang 'Always allow' lalu klik 'Allow / Izinkan'."
    if wait_for_auth 15; then
      echo ">> Tersambung ke TV!"
      return 0
    fi
  fi

  echo ""
  echo "Masukkan IP TV (lihat di TV: Settings > Network > status jaringan), contoh 192.168.1.20"
  read -rp "IP TV: " IP
  IP="${IP%:*}"
  [ -z "$IP" ] && { echo "IP TV tidak boleh kosong."; exit 1; }

  echo ">> Nyambung ke $IP:5555 ... cek layar TV, pilih 'Allow / Izinkan' (centang 'Always allow')"
  adb connect "$IP:5555" >/dev/null 2>&1

  if wait_for_auth 15; then
    echo ">> Tersambung ke TV!"
    return 0
  fi

  echo ""
  echo "Belum nyambung lewat port 5555. Kalau TV punya 'Wireless debugging' dengan kode pairing:"
  echo "buka menu itu di TV > 'Pair device with pairing code', lalu isi di sini."
  read -rp "IP:PORT pairing (contoh 192.168.1.20:37000, Enter untuk batal): " PAIR
  [ -z "$PAIR" ] && { echo "Batal. Pastikan USB debugging ON & HP-TV satu WiFi."; exit 1; }
  read -rp "Kode pairing 6 digit: " CODE
  adb pair "$PAIR" "$CODE"
  read -rp "IP:PORT yang tampil di layar Wireless debugging (bukan port pairing): " CONN
  adb connect "$CONN" >/dev/null 2>&1

  if ! wait_for_auth 15; then
    echo "Masih gagal nyambung. Pastikan IP/port benar dan prompt di layar TV sudah di-Allow."
    exit 1
  fi
  echo ">> Tersambung ke TV!"
}

if [ "$1" = "restore" ]; then
  connect_tv
  [ -f "$LOG" ] || { echo "Log nggak ada ($LOG), nggak ada yang perlu dibalikin."; exit 0; }
  while read -r p; do
    [ -z "$p" ] && continue
    adb shell pm enable --user 0 "$p" >/dev/null 2>&1 \
      || adb shell pm enable "$p" >/dev/null 2>&1 \
      || adb shell cmd package install-existing "$p" >/dev/null 2>&1
    echo "Dibalikin: $p"
  done < "$LOG"
  adb shell settings put global window_animation_scale 1
  adb shell settings put global transition_animation_scale 1
  adb shell settings put global animator_duration_scale 1
  echo ">> Selesai restore. Restart TV ya."
  exit 0
fi

connect_tv

# Aplikasi bawaan & iklan yang aman dimatikan (cuma dimatikan kalau ada di TV)
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
com.xiaomi.mitv.advertise
com.xiaomi.mitv.shop
com.xiaomi.mitv.pay
com.mitv.tvhome.michannel
com.amazon.amazonvideo.livingroom
com.spotify.tv.android
"

# Pengaman: launcher utama, sistem inti, & aplikasi utama TIDAK akan disentuh
PROTECT="netflix|youtube\.tv$|com\.google\.android\.youtube\.tv|(^|\.)(tvlauncher|leanbacklauncher|launcherx|launcher3)$|settings|vending|gms|gsf|katniss|mediashell|inputmethod|tvinput|livetv|tv\.input|systemui|setupwraparound|remote|bluetooth|packageinstaller|webview|tvsettings|providers"

INSTALLED=$(adb shell pm list packages | tr -d '\r' | sed 's/^package://')

echo ""
read -rp "Prime Video & Spotify ikut dimatikan? (y/n, default n): " KILLAPPS
: > "$LOG.tmp"
COUNT=0

for p in $BLOAT; do
  case "$KILLAPPS" in
    [yY]|[yY][eE][sS]) ;;
    *)
      if echo "$p" | grep -qE "amazonvideo|spotify"; then continue; fi
      ;;
  esac

  echo "$p" | grep -qE "$PROTECT" && continue

  if echo "$INSTALLED" | grep -qx "$p"; then
    if adb shell pm disable-user --user 0 "$p" 2>&1 | grep -qi "disabled"; then
      echo "Dimatikan: $p"
      echo "$p" >> "$LOG.tmp"
      COUNT=$((COUNT + 1))
    fi
  fi
done

if [ -s "$LOG.tmp" ]; then
  cat "$LOG" "$LOG.tmp" 2>/dev/null | awk 'NF' | sort -u > "$LOG.new"
  mv "$LOG.new" "$LOG"
fi
rm -f "$LOG.tmp"

# Animasi lebih cepat (bikin menu terasa ngebut) & bersihkan cache aplikasi
adb shell settings put global window_animation_scale 0.5
adb shell settings put global transition_animation_scale 0.5
adb shell settings put global animator_duration_scale 0.5
adb shell pm trim-caches 999G >/dev/null 2>&1 || true

echo ""
echo ">> Total aplikasi bloatware yang baru dimatikan: $COUNT"
echo ">> Aplikasi bawaan merek TV yang terdeteksi (TIDAK disentuh demi keamanan):"
echo "$INSTALLED" | grep -iE "toshiba|tpv|skyworth|hisense|coocaa|tcl|vidaa" || echo "(nggak ada)"
echo ""
echo ">> Beres! Restart TV biar kerasa entengnya. Kalau ada yang aneh: bash tv-debloat.sh restore"
