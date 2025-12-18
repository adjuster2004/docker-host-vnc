#!/bin/bash

# Настройки
CUSTOM_FILE="/data/hosts.custom"

# Создаем директорию для данных
mkdir -p /data

# Инициализация кастомного файла hosts
if [ ! -f "$CUSTOM_FILE" ]; then
    cat > "$CUSTOM_FILE" << 'EOF'
# Docker Hosts Manager - Custom Entries
127.0.0.1   localhost localhost.localdomain
::1         localhost ip6-localhost ip6-loopback

# Примеры:
# 192.168.1.100   myserver.local
# 10.0.0.5        api.local db.local
EOF
    echo "✓ Created hosts.custom file"
fi

# Функция обновления /etc/hosts
update_hosts() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Updating /etc/hosts..."

    cat > /tmp/hosts.tmp << EOF
127.0.0.1 localhost
::1 localhost ip6-localhost ip6-loopback

$(cat "$CUSTOM_FILE")
EOF

    sudo cp /tmp/hosts.tmp /etc/hosts
    echo "✓ Hosts updated"
}

# Первоначальное обновление
update_hosts

# ====== НАСТРОЙКА VNC ПАРОЛЯ ======
echo "Setting up VNC..."

# Очищаем старые файлы
rm -f /tmp/.X99-lock

# Создаем пароль VNC
mkdir -p ~/.vnc
echo "$VNC_PASSWORD" | vncpasswd -f > ~/.vnc/passwd 2>/dev/null || \
    echo "$VNC_PASSWORD" > ~/.vnc/passwd
chmod 600 ~/.vnc/passwd

echo "✓ VNC Password: $VNC_PASSWORD"

# ====== ЗАПУСК Xvfb ======
echo "Starting Xvfb on display $DISPLAY..."

# Запускаем Xvfb
Xvfb $DISPLAY -screen 0 ${RESOLUTION}x24 -ac &
sleep 2

export DISPLAY
echo "DISPLAY set to: $DISPLAY"

# ====== НАСТРОЙКА FLUXBOX ======
mkdir -p ~/.fluxbox

# Минимальный конфиг Fluxbox
echo 'session.screen0.toolbar.visible: true' > ~/.fluxbox/init
echo 'session.screen0.toolbar.height: 20' >> ~/.fluxbox/init

# ====== ЗАПУСК FLUXBOX ======
echo "Starting Fluxbox..."
fluxbox &
sleep 2
echo "✓ Fluxbox started"

# ====== ЗАПУСК VNC СЕРВЕРА ======
echo "Starting VNC server on port $VNC_PORT..."

# Запускаем x11vnc ПРОСТО
x11vnc -display $DISPLAY \
    -forever \
    -shared \
    -passwd "$VNC_PASSWORD" \
    -rfbport $VNC_PORT \
    -bg \
    -quiet &

sleep 3
echo "✓ VNC server started"

# ====== ЗАПУСК noVNC ======
echo "Starting noVNC on port $NOVNC_PORT..."
websockify --web /usr/share/novnc $NOVNC_PORT localhost:$VNC_PORT &
sleep 1
echo "✓ noVNC started"

# ====== ЗАПУСК ВЕБ-ПРИЛОЖЕНИЯ ======
echo "Starting web application on port 5000..."
python3 app.py &
sleep 3
echo "✓ Web application started"

# ====== ЗАПУСК БРАУЗЕРА FIREFOX ======
echo "Launching Firefox browser..."

# Ждем и запускаем Firefox
sleep 3
firefox --display=$DISPLAY http://localhost:5000 &
sleep 5

# Проверяем запуск
if pgrep firefox > /dev/null; then
    echo "✓ Firefox browser launched"
else
    echo "⚠ Firefox not running, will start from menu"
fi

# ====== ИНФОРМАЦИЯ ======
echo ""
echo "=================================================="
echo "        DOCKER HOSTS MANAGER - READY!"
echo "=================================================="
echo ""
echo "ACCESS:"
echo "• Web Interface:  http://localhost:5000"
echo "• Web VNC:        http://localhost:6080/vnc.html"
echo "• Direct VNC:     localhost:$VNC_PORT"
echo "• VNC Password:   $VNC_PASSWORD"
echo ""
echo "IN VNC DESKTOP:"
echo "• Firefox browser (non-snap version)"
echo "• Mousepad text editor"
echo "• xterm terminal"
echo ""
echo "If browser not visible:"
echo "1. Right-click desktop → Applications → Firefox"
echo "2. Or open terminal: firefox http://localhost:5000"
echo "=================================================="

# ====== МОНИТОРИНГ ======
while true; do
    # Мониторинг изменений hosts
    if [ -f "$CUSTOM_FILE" ]; then
        CURRENT_MD5=$(md5sum "$CUSTOM_FILE" 2>/dev/null | cut -d' ' -f1)

        if [ "$CURRENT_MD5" != "$LAST_MD5" ]; then
            echo "[$(date '+%H:%M:%S')] Hosts file changed, updating..."
            update_hosts
            LAST_MD5="$CURRENT_MD5"
        fi
    fi

    sleep 10
done
