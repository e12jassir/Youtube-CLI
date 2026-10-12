#!/usr/bin/env bash
set -e

INSTALL_DIR="${DESTDIR:-$HOME/.local/bin}"
mkdir -p "$INSTALL_DIR"

echo "==> Instalando yt-cli en $INSTALL_DIR..."
install -m 755 bin/yt "$INSTALL_DIR/yt"
install -m 755 bin/yt-thumb-preview "$INSTALL_DIR/yt-thumb-preview"

echo "==> Verificando dependencias..."
for dep in fzf yt-dlp mpv curl python3; do
    if command -v "$dep" >/dev/null 2>&1; then
        echo "  [✓] $dep"
    else
        echo "  [!] $dep no encontrado (recomendado instalar)"
    fi
done

CONFIG_DEST="${XDG_CONFIG_HOME:-$HOME/.config}/yt"
if [ ! -f "$CONFIG_DEST/config" ]; then
    mkdir -p "$CONFIG_DEST"
    cp config.example "$CONFIG_DEST/config"
    echo "  [i] Archivo de configuración generado en $CONFIG_DEST/config"
fi

echo ""
echo "✅ Instalación completada exitosamente."
echo "Ejecuta 'yt' en tu terminal para iniciar."
