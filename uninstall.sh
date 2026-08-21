#!/bin/sh

echo "[+] Остановка и удаление службы happ-decoder..."

# 1. Остановка и отключение автозапуска
if [ -f /etc/init.d/happ-decoder ]; then
    /etc/init.d/happ-decoder stop 2>/dev/null
    /etc/init.d/happ-decoder disable 2>/dev/null
fi

# 2. Удаление APK пакета через apk-tools
if apk info -e luci-app-happ-decoder >/dev/null 2>&1; then
    apk del luci-app-happ-decoder
else
    echo "[-] Пакет luci-app-happ-decoder не найден в системе."
fi

# 3. Полная очистка оставшихся файлов и конфигов
rm -f /etc/config/happ-decoder
rm -f /usr/bin/happ-decoder
rm -f /etc/init.d/happ-decoder
rm -f /usr/share/luci/menu.d/luci-app-happ-decoder.json
rm -f /usr/share/rpcd/acl.d/luci-app-happ-decoder.json
rm -rf /www/luci-static/resources/view/happ-decoder

# 4. Сброс кэша LuCI
rm -rf /tmp/luci-indexcache /tmp/luci-modulecache/

echo "[+] Удаление полностью завершено!"
