#!/bin/sh
# Telegram Desktop in a smolvm microVM. Wayland goes through waypipe over one mounted socket.
set -eu
cd "$(dirname "$0")"
dl=${XDG_DOWNLOAD_DIR:-$(xdg-user-dir DOWNLOAD)}
mkdir -p home bin share "$dl/Telegram Desktop"

# First run only: Telegram updates itself in ./bin afterwards (TLS only, no signature check).
if [ ! -x bin/Telegram ]; then
  echo 'a2032e74a3c57c183cc280938b89d85d965fd8d1eacbfb5967faa7b3bee402ca  td-setup-linux-x64-7.4.3.tar.xz' | sha256sum -c
  tar -xJf td-setup-linux-x64-7.4.3.tar.xz --strip-components=1 -C bin
fi
# Delete image.tar to rebuild.
[ -f image.tar ] || { docker build -t telegram-smolvm . && docker save telegram-smolvm -o image.tar; }

sock=$XDG_RUNTIME_DIR/telegram-waypipe.sock
rm -f "$sock"
waypipe --no-gpu -s "$sock" client &
trap 'kill $! 2>/dev/null' EXIT INT TERM

# The guest starts as root only to symlink $DL (drag and drop passes host paths; smolvm 1.34
# panics on non-ASCII guest mount paths), then drops to your uid, which owns the mounted files.
smolvm machine run --block-private --cpus 4 --mem 6144 \
  -e HOME=/home/telegram -e XDG_RUNTIME_DIR=/tmp -e QT_QPA_PLATFORM=wayland -e QT_ACCESSIBILITY=0 \
  -e MOZ_ENABLE_WAYLAND=1 -e TZ="$(tail -n1 /etc/localtime)" \
  -e DL="$dl" -e U="$(id -u)" -e G="$(id -g)" \
  -v "$PWD/home:/home/telegram" -v "$PWD/bin:/opt/Telegram" -v "$PWD/share:/share" \
  -v "$dl:/mnt/dl:ro" -v "$dl/Telegram Desktop:/mnt/tgdl" \
  --mount-socket "$sock:/run/waypipe.sock" --image ./image.tar -- sh -c '
    set -e; mount --bind /mnt/tgdl "/mnt/dl/Telegram Desktop"  # smolvm cannot nest it
    mkdir -p "$(dirname "$DL")" && ln -sfn /mnt/dl "$DL"
    rmdir /home/telegram/Downloads 2>/dev/null || true; ln -sfn /mnt/dl /home/telegram/Downloads
    exec setpriv --reuid="$U" --regid="$G" --clear-groups --no-new-privs \
      waypipe --no-gpu -s /run/waypipe.sock server -- /opt/Telegram/Telegram'
