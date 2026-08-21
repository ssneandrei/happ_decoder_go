#!/bin/sh

# 1. Определение архитектуры OpenWrt 25
ARCH=$(apk info --print-arch)

case "$ARCH" in
  aarch64)
    PKG_ARCH="aarch64"
    ;;
  mips* | mipsle*)
    PKG_ARCH="mips"
    ;;
  x86_64)
    PKG_ARCH="x86_64"
    ;;
  *)
    echo "[-] Неподдерживаемая архитектура: $ARCH"
    exit 1
    ;;
esac

echo "[+] Определена архитектура: $PKG_ARCH"

# 2. Получение ссылки на последний релиз с GitHub API
DOWNLOAD_URL=$(wget -qO- https://api.github.com/repos/ssneandrei/happ_decoder_go/releases/latest | \
  grep "browser_download_url" | \
  grep "_${PKG_ARCH}\.apk" | \
  cut -d '"' -f 4)

if [ -z "$DOWNLOAD_URL" ]; then
  echo "[-] Не удалось найти подходящий .apk пакет в последнем релизе."
  exit 1
fi

echo "[+] Скачивание: $DOWNLOAD_URL"
wget -O /tmp/happ-decoder.apk "$DOWNLOAD_URL"

# 3. Установка и очистка
echo "[+] Установка пакета в OpenWrt..."
apk add --allow-untrusted /tmp/happ-decoder.apk
rm -f /tmp/happ-decoder.apk

echo "[+] Установка успешно завершена! Настройки доступны в LuCI: Службы -> Happ Decoder"
