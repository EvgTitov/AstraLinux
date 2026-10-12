#!/bin/bash
# Генерация клиентских сертификатов OpenVPN.
# Запуск: sudo ./gen_certs.sh

set -u

# ==== НАСТРОЙКИ ====
VPN_PREFIX="172.18.0"
IP_START=8
TARGET_IP="192.168.7.72"
CERTS_DIR="/home/user/certs"
CCD_DIR="/etc/openvpn/ccd"
IPTABLES_FILE="/home/user/iptables_rules.txt"

# ==== УЖЕ СДЕЛАННЫЕ (пропускаем) ====
DONE_USERS=(
"s.agapitov"
"v.demchuk"
"r.kazakov"
)

# ==== СПИСОК ПОЛЬЗОВАТЕЛЕЙ (username:password) ====
USERS=(
"y.belousov:PASSWORD_HERE"
"o.popov:PASSWORD_HERE"
"e.galchanskiy:PASSWORD_HERE"
"g.artamonov:PASSWORD_HERE"
"r.silantyev:PASSWORD_HERE"
"v.bryzgalov:PASSWORD_HERE"
"n.pyskov:PASSWORD_HERE"
"v.sitnik:PASSWORD_HERE"
"a.h.hasanov:PASSWORD_HERE"
"v.biruchkov:PASSWORD_HERE"
"a.popov:PASSWORD_HERE"
"d.shulepov:PASSWORD_HERE"
"s.cherkasov:PASSWORD_HERE"
"d.vetoshkin:PASSWORD_HERE"
"v.plotnikov:PASSWORD_HERE"
"d.lukin:PASSWORD_HERE"
"d.nuyandin:PASSWORD_HERE"
"v.kerzhencev:PASSWORD_HERE"
"b.sarbaev:PASSWORD_HERE"
"s.terenin:PASSWORD_HERE"
"g.nigmatullin:PASSWORD_HERE"
"r.novikov:PASSWORD_HERE"
"p.shamin:PASSWORD_HERE"
"a.askhadulin:PASSWORD_HERE"
"o.stogniy:PASSWORD_HERE"
"a.zabrodin:PASSWORD_HERE"
"a.getmanov:PASSWORD_HERE"
"m.kazakov:PASSWORD_HERE"
"y.bolshakov:PASSWORD_HERE"
"b.ignatov:PASSWORD_HERE"
"y.sadovnichaya:PASSWORD_HERE"
"a.gryaznyh:PASSWORD_HERE"
)

# ==== ЦВЕТА ====
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

mkdir -p "$CERTS_DIR" "$CCD_DIR"
: > "$IPTABLES_FILE"

echo -e "${GREEN}=== Уже сделаны (пропускаем): ${DONE_USERS[*]} ===${NC}"
echo ""

i=0
for entry in "${USERS[@]}"; do
    USERNAME="${entry%%:*}"
    PASSWORD="${entry#*:}"
    OCTET=$((IP_START + i))
    TUNNEL_IP="${VPN_PREFIX}.${OCTET}"

    echo -e "${YELLOW}=== [$((i+1))/${#USERS[@]}] $USERNAME (туннель: $TUNNEL_IP) ===${NC}"

    if astra-openvpn-server client "$USERNAME" >/dev/null 2>&1; then
        echo -e "  ${GREEN}+ сертификат создан${NC}"
    else
        echo -e "  ${RED}! ошибка создания сертификата${NC}"
        i=$((i+1))
        continue
    fi

    cd "/etc/openvpn/clients_keys/$USERNAME" || { i=$((i+1)); continue; }

    if printf "%s\n%s\n" "$PASSWORD" "$PASSWORD" | \
        openssl pkcs12 -export \
        -in "$USERNAME.crt" \
        -inkey "$USERNAME.key" \
        -certfile ca.crt \
        -name "$USERNAME" \
        -out "$USERNAME.p12" \
        -passout pass:"$PASSWORD" 2>/dev/null; then
        echo -e "  ${GREEN}+ $USERNAME.p12 создан${NC}"
    else
        echo -e "  ${RED}! ошибка openssl pkcs12${NC}"
    fi

    cp "$USERNAME.p12" "$CERTS_DIR/" 2>/dev/null
    echo "ifconfig-push $TUNNEL_IP 255.255.255.0" > "$CCD_DIR/$USERNAME"
    echo -e "  ${GREEN}+ ccd: $TUNNEL_IP${NC}"
    echo "-s $TUNNEL_IP -d $TARGET_IP -j ACCEPT  #$USERNAME" >> "$IPTABLES_FILE"

    i=$((i+1))
done

chown -R user:user "$CERTS_DIR"
chmod 600 "$CERTS_DIR"/*.p12 2>/dev/null

echo ""
echo -e "${GREEN}=== ГОТОВО ===${NC}"
echo -e "Сертификаты:      ${GREEN}$CERTS_DIR${NC}"
echo -e "CCD:              ${GREEN}$CCD_DIR${NC}"
echo -e "Правила iptables: ${GREEN}$IPTABLES_FILE${NC}"
