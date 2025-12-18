#!/bin/bash
echo "Обновление /etc/hosts..."

sudo bash -c "cat > /etc/hosts << 'EOF'
127.0.0.1 localhost
::1 localhost ip6-localhost ip6-loopback

# Custom entries
$(cat /data/hosts.custom 2>/dev/null || echo '# No custom entries')
EOF"

echo "✓ Hosts обновлен"
