#!/bin/bash

SOURCE="/mnt/Smeta/"
DEST="/data/Smeta/"

echo "========================================="
echo "СТАТУС СИНХРОНИЗАЦИИ"
echo "========================================="
echo ""

echo "📁 ИСТОЧНИК ($SOURCE):"
if mountpoint -q /mnt/Smeta/; then
    echo "  ✅ смонтирован"
    SOURCE_FILES=$(find "$SOURCE" -type f 2>/dev/null | wc -l)
    SOURCE_SIZE=$(du -sh "$SOURCE" 2>/dev/null | cut -f1)
    echo "  Файлов: $SOURCE_FILES"
    echo "  Размер: $SOURCE_SIZE"
else
    echo "  ❌ НЕ смонтирован"
fi

echo ""
echo "📁 ПРИЕМНИК ($DEST):"
if [ -d "$DEST" ]; then
    DEST_FILES=$(find "$DEST" -type f 2>/dev/null | wc -l)
    DEST_SIZE=$(du -sh "$DEST" 2>/dev/null | cut -f1)
    echo "  Файлов: $DEST_FILES"
    echo "  Размер: $DEST_SIZE"
else
    echo "  ❌ Папка не существует"
fi

echo ""
echo "🔍 СРАВНЕНИЕ:"
if [ "$SOURCE_FILES" = "$DEST_FILES" ] 2>/dev/null; then
    echo "  ✅ Количество файлов совпадает: $SOURCE_FILES"
else
    echo "  ⚠️ Количество файлов РАЗЛИЧАЕТСЯ:"
    echo "     Источник: $SOURCE_FILES"
    echo "     Приемник: $DEST_FILES"
fi

echo ""
echo "📋 ПОСЛЕДНИЙ ЛОГ:"
LAST_LOG=$(ls -t /data/logs/sync_*.log 2>/dev/null | head -1)
if [ -n "$LAST_LOG" ]; then
    echo "  Файл: $(basename $LAST_LOG)"
    echo "  Время: $(stat -c %y $LAST_LOG | cut -d. -f1)"
    echo "  Результат: $(tail -5 $LAST_LOG | grep -E "✅|❌|ОШИБКА" | tail -1)"
else
    echo "  ❌ Логов пока нет"
fi

echo ""
echo "========================================="
