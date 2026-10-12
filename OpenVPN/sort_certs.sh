#!/bin/bash
# Раскладывает .ovpn, .p12 и ta.key по папкам <username>/.
# Запуск: sudo ./sort_certs.sh

set -u

CERTS_DIR="/home/user/certs"
TA_KEY="$CERTS_DIR/ta.key"

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

if [ ! -f "$TA_KEY" ]; then
    echo -e "${RED}ОШИБКА: $TA_KEY не найден. Сначала выполните gen_ovpn.sh${NC}"
    exit 1
fi

COUNT=0
for p12 in "$CERTS_DIR"/*.p12; do
    [ -f "$p12" ] || continue
    USERNAME=$(basename "$p12" .p12)
    USER_DIR="$CERTS_DIR/$USERNAME"

    mkdir -p "$USER_DIR"
    mv "$CERTS_DIR/$USERNAME.p12"  "$USER_DIR/"
    mv "$CERTS_DIR/$USERNAME.ovpn" "$USER_DIR/" 2>/dev/null
    cp "$TA_KEY" "$USER_DIR/"

    chown -R user:user "$USER_DIR"
    chmod 600 "$USER_DIR"/*.p12 "$USER_DIR"/*.ovpn "$USER_DIR/ta.key" 2>/dev/null
    echo -e "${GREEN}+ $USERNAME/${NC}"
    COUNT=$((COUNT+1))
done

rm -f "$CERTS_DIR"/*.p12 "$CERTS_DIR"/*.ovpn

echo ""
echo -e "${GREEN}=== ГОТОВО ===${NC}"
echo -e "Папок: ${GREEN}$COUNT${NC}"
echo ""
ls -d "$CERTS_DIR"/*/ 2>/dev/null | head -40
