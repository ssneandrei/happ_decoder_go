#!/bin/sh
ARCH=$(uname -m)
case "$ARCH" in
aarch64)
APK_ARCH="aarch64"
;;
x86_64)
APK_ARCH="x86_64"
;;
mips|mipsel)
APK_ARCH="mips"
;;
*)
echo "Неподдерживаемая архитектура: $ARCH"
exit 1
;;
esac
echo "Обнаружена архитектура: $APK_ARCH"
RELEASE_URL=$(wget -qO- https://api.github.com/repos/ssneandrei/happ_decoder_go/releases/latest | grep "browser_download_url.*.apk" | cut -d '"' -f 4)
if [ -z "$RELEASE_URL" ]; then
echo "Не удалось найти файл .apk в последнем релизе!"
exit 1
fi
echo "Загрузка пакета: $RELEASE_URL"
wget -O /tmp/happ-decoder.apk "$RELEASE_URL"
echo "Установка пакета..."
apk add --allow-untrusted /tmp/happ-decoder.apk
rm -f /tmp/happ-decoder.apk
echo "Установка успешно завершена!"
