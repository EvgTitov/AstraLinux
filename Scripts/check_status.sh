#!/bin/bash

echo "========================================="
echo "СТАТУС СИНХРОНИЗАЦИИ"
echo "========================================="
echo ""

echo "📁 ИСТОЧНИК (NFS /mnt/Smeta/):"
if mountpoint -q /mnt/Smeta/; then
    echo "  ✅ NFS смонтирован"
    echo "  Файлов: $(sudo find /mnt/Smeta/ -type f 2>/dev/null | wc -l)"
    echo "  Размер: $(sudo du -sh /mnt/Smeta/ 2>/dev/null | cut -f1)"
else
    echo "  ❌ NFS НЕ смонтирован"
fi

echo ""
echo "📁 ПРИЕМНИК (/data/Smeta/):"
if [ -d "/data/Smeta/" ]; then
    echo "  Файлов: $(find /data/Smeta/ -type f 2>/dev/null | wc -l)"
    echo "  Размер: $(du -sh /data/Smeta/ 2>/dev/null | cut -f1)"
else
    echo "  ❌ Папка не существует"
fi

echo ""
echo "📋 ПОСЛЕДНИЕ ЛОГИ:"
ls -lt /data/logs/sync_*.log 2>/dev/null | head -5

echo ""
echo "📄 ПОСЛЕДНЯЯ СИНХРОНИЗАЦИЯ:"
LAST_LOG=$(ls -t /data/logs/sync_*.log 2>/dev/null | head -1)
if [ -n "$LAST_LOG" ]; then
    echo "  Файл: $(basename $LAST_LOG)"
    echo "  Время: $(stat -c %y $LAST_LOG | cut -d. -f1)"
    echo "  Результат: $(tail -3 $LAST_LOG | grep -E "✅|❌|ОШИБКА" | tail -1)"
else
    echo "  Логов пока нет"
fi

echo ""
echo "========================================="
