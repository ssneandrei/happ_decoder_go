#!/bin/sh
set -eu

ARCH=$(uname -m)
case "$ARCH" in
    aarch64) APK_ARCH="aarch64" ;;
    x86_64)  APK_ARCH="x86_64" ;;
    mips|mipsel) APK_ARCH="mips" ;;
    *)
        echo "❌ Неподдерживаемая архитектура: $ARCH"
        exit 1
        ;;
esac

echo "✅ Архитектура: $APK_ARCH"

# Ищем файл с нужной архитектурой
RELEASE_URL=$(wget -qO- https://api.github.com/repos/ssneandrei/happ_decoder_go/releases/latest \
    | grep "browser_download_url.*luci-app-happ-decoder.*$APK_ARCH.*\.apk" \
    | cut -d '"' -f 4 \
    | head -n 1)

if [ -z "$RELEASE_URL" ]; then
    echo "❌ Не найден APK для архитектуры $APK_ARCH"
    exit 1
fi

echo "📥 Загрузка: $RELEASE_URL"
wget -O /tmp/happ-decoder.apk "$RELEASE_URL" || {
    echo "❌ Ошибка загрузки"
    exit 1
}

echo "⚙️ Установка..."
# Проверяем что файл существует и не пустой
if [ ! -s /tmp/happ-decoder.apk ]; then
    echo "❌ Файл пустой или не существует"
    exit 1
fi

apk add --allow-untrusted /tmp/happ-decoder.apk || {
    echo "❌ Ошибка установки. Проверьте зависимости и целостность пакета"
    exit 1
}

rm -f /tmp/happ-decoder.apk
echo "✅ Установка завершена!"
