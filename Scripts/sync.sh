#!/bin/bash

SOURCE="/mnt/Smeta/"
DEST="/data/Smeta/"
LOG_DIR="/data/logs"
LOG_FILE="$LOG_DIR/sync_$(date +%Y%m%d_%H%M%S).log"

# Опции rsync: сохраняем всё, что можем
RSYNC_OPTS="-aavh --delete --progress"

mkdir -p "$LOG_DIR"
mkdir -p "$DEST"

echo "==================================================" | tee "$LOG_FILE"
echo "СИНХРОНИЗАЦИЯ: $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$LOG_FILE"
echo "Источник: $SOURCE" | tee -a "$LOG_FILE"
echo "Приемник: $DEST" | tee -a "$LOG_FILE"
echo "Режим: Зеркалирование (с удалением лишнего)" | tee -a "$LOG_FILE"
echo "==================================================" | tee -a "$LOG_FILE"

# Проверка монтирования
if ! mountpoint -q /mnt/Smeta/ 2>/dev/null; then
    echo "❌ ОШИБКА: /mnt/Smeta/ не является точкой монтирования" | tee -a "$LOG_FILE"
    exit 1
fi
echo "✅ /mnt/Smeta смонтирован" | tee -a "$LOG_FILE"

# Проверка доступа к источнику
if ! test -d "$SOURCE"; then
    echo "❌ ОШИБКА: Нет доступа к источнику $SOURCE" | tee -a "$LOG_FILE"
    exit 1
fi
echo "✅ Доступ к источнику есть" | tee -a "$LOG_FILE"

SOURCE_FILES=$(find "$SOURCE" -type f 2>/dev/null | wc -l)
echo "Файлов в источнике: $SOURCE_FILES" | tee -a "$LOG_FILE"

echo ""
echo "Запуск синхронизации..." | tee -a "$LOG_FILE"
echo "==================================================" | tee -a "$LOG_FILE"

# Запуск rsync
rsync $RSYNC_OPTS "$SOURCE" "$DEST" 2>&1 | tee -a "$LOG_FILE"

RSYNC_EXIT_CODE=${PIPESTATUS[0]}

if [ $RSYNC_EXIT_CODE -eq 0 ]; then
    echo "==================================================" | tee -a "$LOG_FILE"
    echo "✅ СИНХРОНИЗАЦИЯ УСПЕШНО ЗАВЕРШЕНА" | tee -a "$LOG_FILE"

    DEST_FILES=$(find "$DEST" -type f 2>/dev/null | wc -l)
    DEST_SIZE=$(du -sh "$DEST" 2>/dev/null | cut -f1)
    echo "Файлов в приемнике: $DEST_FILES" | tee -a "$LOG_FILE"
    echo "Размер приемника: $DEST_SIZE" | tee -a "$LOG_FILE"

    echo ""
    echo "Восстановление ACL на /data/Smeta..." | tee -a "$LOG_FILE"

    # Очистка и восстановление ACL
    setfacl -b /data/Smeta
    chmod 750 /data/Smeta

    setfacl -m g:28602:r-x /data/Smeta
    setfacl -m g:28603:rwx /data/Smeta
    setfacl -m g:16312:rwx /data/Smeta
    setfacl -m g:31922:--- /data/Smeta

    setfacl -d -m g:28602:r-x /data/Smeta
    setfacl -d -m g:28603:rwx /data/Smeta
    setfacl -d -m g:16312:rwx /data/Smeta
    setfacl -d -m g:31922:--- /data/Smeta

    setfacl -R -m g:28602:r-x /data/Smeta
    setfacl -R -m g:28603:rwx /data/Smeta
    setfacl -R -m g:16312:rwx /data/Smeta
    setfacl -R -m g:31922:--- /data/Smeta

    setfacl -R -m mask::rwx /data/Smeta

    echo "✅ ACL сохранены" | tee -a "$LOG_FILE"

else
    echo "==================================================" | tee -a "$LOG_FILE"
    echo "❌ ОШИБКА ПРИ СИНХРОНИЗАЦИИ (код: $RSYNC_EXIT_CODE)" | tee -a "$LOG_FILE"
    exit 1
fi

echo ""
echo "Лог сохранен: $LOG_FILE" | tee -a "$LOG_FILE"
echo "==================================================" | tee -a "$LOG_FILE"

exit 0
