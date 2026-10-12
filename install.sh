#!/usr/bin/env bash
# yt installer.  Usage: ./install.sh [--uninstall]
# PREFIX (default ~/.local) and BINDIR (default $PREFIX/bin) are honoured.
set -euo pipefail

PREFIX="${PREFIX:-$HOME/.local}"
BINDIR="${BINDIR:-$PREFIX/bin}"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILES=(yt yt-fmt yt-thumb-preview)

if [ "${1:-}" = "--uninstall" ]; then
    for f in "${FILES[@]}"; do rm -f "$BINDIR/$f"; done
    echo "yt removed from $BINDIR (config, cache and history were left untouched)"
    exit 0
fi

if [ "${BASH_VERSINFO[0]}" -lt 4 ]; then
    echo "yt needs bash >= 4 (macOS: brew install bash)" >&2
    exit 1
fi

echo "==> Installing yt into $BINDIR"
mkdir -p "$BINDIR"
for f in "${FILES[@]}"; do install -m 755 "$SRC/bin/$f" "$BINDIR/$f"; done

CONFIG_DEST="${XDG_CONFIG_HOME:-$HOME/.config}/yt"
if [ ! -f "$CONFIG_DEST/config" ]; then
    mkdir -p "$CONFIG_DEST"
    cp "$SRC/config.example" "$CONFIG_DEST/config"
    echo "==> Default config written to $CONFIG_DEST/config"
fi

hint() {
    if   command -v pacman  >/dev/null 2>&1; then echo "sudo pacman -S $*"
    elif command -v apt-get >/dev/null 2>&1; then echo "sudo apt install $*"
    elif command -v dnf     >/dev/null 2>&1; then echo "sudo dnf install $*"
    elif command -v brew    >/dev/null 2>&1; then echo "brew install $*"
    else echo "install: $*"; fi
}

echo "==> Checking dependencies"
missing=()
for dep in fzf yt-dlp mpv curl python3; do
    if command -v "$dep" >/dev/null 2>&1; then echo "  [ok] $dep"
    else echo "  [!!] $dep"; missing+=("$dep"); fi
done
[ "${#missing[@]}" -gt 0 ] && echo "     $(hint "${missing[*]}")"

if ! command -v deno >/dev/null 2>&1 && ! command -v node >/dev/null 2>&1 && ! command -v bun >/dev/null 2>&1; then
    echo "  [!!] JS runtime: since yt-dlp 2025.11 YouTube needs one (deno recommended: https://deno.com)"
fi

case ":$PATH:" in *":$BINDIR:"*) ;; *) echo "  [i] add $BINDIR to your PATH" ;; esac

echo
echo "Done. Run 'yt --doctor' to verify your setup, then 'yt'."
