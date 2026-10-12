#!/bin/bash
# Проверка .p12 по паролям.
# Запуск: ./check_p12.sh

set -u

CERTS_DIR="/home/user/certs"

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

OK=0
FAIL=0
for entry in "${USERS[@]}"; do
    USERNAME="${entry%%:*}"
    PASSWORD="${entry#*:}"

    if openssl pkcs12 -in "$CERTS_DIR/$USERNAME.p12" -info -noout \
        -passin pass:"$PASSWORD" 2>/dev/null; then
        echo "✅ $USERNAME"
        OK=$((OK+1))
    else
        echo "❌ $USERNAME"
        FAIL=$((FAIL+1))
    fi
done

echo ""
echo "Итого: OK=$OK, FAIL=$FAIL"
