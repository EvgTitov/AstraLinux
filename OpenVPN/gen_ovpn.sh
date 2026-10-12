#!/bin/bash
# Генерация <user>.ovpn со ссылками на <user>.p12 и ta.key.
# Запуск: sudo ./gen_ovpn.sh

set -u

CERTS_DIR="/home/user/certs"
TA_KEY="/etc/openvpn/keys/ta.key"
SERVER_IP="192.168.168.226"
SERVER_PORT="1194"

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

if [ ! -f "$TA_KEY" ]; then
    echo -e "${RED}ОШИБКА: $TA_KEY не найден${NC}"
    exit 1
fi

cp "$TA_KEY" "$CERTS_DIR/ta.key"
chown user:user "$CERTS_DIR/ta.key"

COUNT=0
for p12 in "$CERTS_DIR"/*.p12; do
    [ -f "$p12" ] || continue
    USERNAME=$(basename "$p12" .p12)

    cat > "$CERTS_DIR/$USERNAME.ovpn" <<EOF
client
dev tun
proto tcp
remote $SERVER_IP $SERVER_PORT
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-GCM
auth SHA256
verb 3
pkcs12 $USERNAME.p12
tls-auth ta.key 1
EOF

    chown user:user "$CERTS_DIR/$USERNAME.ovpn"
    chmod 644 "$CERTS_DIR/$USERNAME.ovpn"
    echo -e "${GREEN}+ $USERNAME.ovpn${NC}"
    COUNT=$((COUNT+1))
done

echo ""
echo -e "${GREEN}=== ГОТОВО ===${NC}"
echo -e "Создано .ovpn: ${GREEN}$COUNT${NC}"
