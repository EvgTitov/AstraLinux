#!/bin/bash

# ======================================================
# Скрипт резервного копирования файлов документооборота
# Источник: srv-1c-doc:/mnt/DATA/doc3files
# Приёмник: /mnt/DATA/doc3files (локально на srv-1c-acc)
# Режим: ТОЛЬКО ДОБАВЛЕНИЕ (без замены и без удаления)
# ======================================================

SOURCE_HOST="srv-1c-doc"
SOURCE_DIR="/mnt/DATA/doc3files/"
DEST_DIR="/mnt/DATA/doc3files/"
LOG_DIR="/data/logs"
LOG_FILE="$LOG_DIR/sync_doc3files_$(date +%Y%m%d_%H%M%S).log"
REPORT_LOG="/data/logs/doc3files_last_report.log"

# Настройки почты
EMAIL_TO="*********, *********"
EMAIL_FROM="web-mail@gap-rt.ru"
SMTP_SERVER="mail1.gap-rt.ru"
SMTP_PORT="25"
SMTP_USER="*********"
SMTP_PASS="*********"

# Параметры rsync (БЕЗ --delete, БЕЗ --update, только --ignore-existing)
RSYNC_OPTS="-avzh --progress --ignore-existing --no-perms --no-owner --no-group"

mkdir -p "$LOG_DIR"
mkdir -p "$DEST_DIR" 2>/dev/null || true

# Функция отправки письма через SMTP
send_email() {
    local subject="$1"
    local body="$2"
    local tmp_email="/tmp/email_$$.txt"
    
    cat > "$tmp_email" << EOF
From: $EMAIL_FROM
To: *********, *********
Subject: $subject
MIME-Version: 1.0
Content-Type: text/plain; charset=utf-8

$body
EOF

    curl -s --url "smtp://$SMTP_SERVER:$SMTP_PORT" \
        --mail-from "$EMAIL_FROM" \
        --mail-rcpt "s.kalistratov@gap-rt.ru" \
        --mail-rcpt "a.senyushin@gap-rt.ru" \
        --upload-file "$tmp_email" \
        --user "$SMTP_USER:$SMTP_PASS" \
        2>&1
    
    rm -f "$tmp_email"
}

# Начало лога
echo "==================================================" | tee "$LOG_FILE"
echo "СИНХРОНИЗАЦИЯ doc3files: $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$LOG_FILE"
echo "Источник: $SOURCE_HOST:$SOURCE_DIR" | tee -a "$LOG_FILE"
echo "Приемник: $DEST_DIR" | tee -a "$LOG_FILE"
echo "Режим: ТОЛЬКО ДОБАВЛЕНИЕ (без замены и удаления)" | tee -a "$LOG_FILE"
echo "==================================================" | tee -a "$LOG_FILE"

START_TIME=$(date +%s)

# Проверка доступности источника
echo "Проверка доступности $SOURCE_HOST..." | tee -a "$LOG_FILE"
if ! ssh -o ConnectTimeout=10 -o BatchMode=yes "$SOURCE_HOST" "echo OK" >/dev/null 2>&1; then
    ERROR_MSG="❌ ОШИБКА: Сервер $SOURCE_HOST недоступен по SSH"
    echo "$ERROR_MSG" | tee -a "$LOG_FILE"
    
    BODY="
=============================================
ОШИБКА РЕЗЕРВНОГО КОПИРОВАНИЯ doc3files
=============================================

Статус: ❌ ОШИБКА
Дата: $(date '+%Y-%m-%d %H:%M:%S')

$ERROR_MSG

Проверьте доступность сервера $SOURCE_HOST.

Лог: $LOG_FILE
============================================="
    
    send_email "❌ ERROR: doc3files backup - сервер недоступен" "$BODY"
    exit 1
fi
echo "✅ $SOURCE_HOST доступен" | tee -a "$LOG_FILE"

# Проверка папки на источнике
echo "Проверка папки $SOURCE_DIR на $SOURCE_HOST..." | tee -a "$LOG_FILE"
if ! ssh "$SOURCE_HOST" "test -d '$SOURCE_DIR'" 2>/dev/null; then
    ERROR_MSG="❌ ОШИБКА: Папка $SOURCE_DIR не существует на $SOURCE_HOST"
    echo "$ERROR_MSG" | tee -a "$LOG_FILE"
    
    BODY="
=============================================
ОШИБКА РЕЗЕРВНОГО КОПИРОВАНИЯ doc3files
=============================================

Статус: ❌ ОШИБКА
Дата: $(date '+%Y-%m-%d %H:%M:%S')

$ERROR_MSG

Проверьте наличие папки на источнике.

Лог: $LOG_FILE
============================================="
    
    send_email "❌ ERROR: doc3files backup - папка не найдена" "$BODY"
    exit 1
fi
echo "✅ Папка на источнике существует" | tee -a "$LOG_FILE"

# Статистика источника
SOURCE_FILES=$(ssh "$SOURCE_HOST" "find '$SOURCE_DIR' -type f 2>/dev/null | wc -l")
SOURCE_SIZE=$(ssh "$SOURCE_HOST" "du -sh '$SOURCE_DIR' 2>/dev/null | cut -f1")
echo "Файлов в источнике: $SOURCE_FILES" | tee -a "$LOG_FILE"
echo "Размер источника: $SOURCE_SIZE" | tee -a "$LOG_FILE"

# Статистика приёмника до копирования
DEST_FILES_BEFORE=$(find "$DEST_DIR" -type f 2>/dev/null | wc -l)
echo "Файлов в приемнике до копирования: $DEST_FILES_BEFORE" | tee -a "$LOG_FILE"

echo ""
echo "Запуск копирования (только новые файлы)..." | tee -a "$LOG_FILE"
echo "==================================================" | tee -a "$LOG_FILE"

rsync $RSYNC_OPTS -e "ssh -o ConnectTimeout=30" \
    "$SOURCE_HOST:$SOURCE_DIR" "$DEST_DIR" 2>&1 | tee -a "$LOG_FILE"

RSYNC_EXIT=${PIPESTATUS[0]}

echo "==================================================" | tee -a "$LOG_FILE"

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
DURATION_MIN=$((DURATION / 60))
DURATION_SEC=$((DURATION % 60))

# Статистика приёмника после копирования
DEST_FILES_AFTER=$(find "$DEST_DIR" -type f 2>/dev/null | wc -l)
DEST_SIZE=$(du -sh "$DEST_DIR" 2>/dev/null | cut -f1)
NEW_FILES=$((DEST_FILES_AFTER - DEST_FILES_BEFORE))

# Формирование статуса
if [ $RSYNC_EXIT -eq 0 ]; then
    STATUS="✅ УСПЕШНО"
    SUBJECT="✅ OK: doc3files backup - добавлено $NEW_FILES файлов"
elif [ $RSYNC_EXIT -eq 23 ]; then
    STATUS="⚠️ ЧАСТИЧНАЯ ОШИБКА (код: $RSYNC_EXIT)"
    SUBJECT="⚠️ PARTIAL: doc3files backup - частичная ошибка"
else
    STATUS="❌ ОШИБКА (код: $RSYNC_EXIT)"
    SUBJECT="❌ ERROR: doc3files backup - ошибка при копировании"
fi

BODY="
=============================================
ОТЧЁТ О РЕЗЕРВНОМ КОПИРОВАНИИ doc3files
=============================================

Статус:          $STATUS
Дата запуска:    $(date -d @$START_TIME '+%Y-%m-%d %H:%M:%S')
Длительность:    $DURATION_MIN мин $DURATION_SEC сек

Источник:        $SOURCE_HOST:$SOURCE_DIR
Приёмник:        $DEST_DIR
Режим:           ТОЛЬКО ДОБАВЛЕНИЕ (без замены и удаления)

Статистика:
  Файлов в источнике:      $SOURCE_FILES
  Размер источника:        $SOURCE_SIZE
  Файлов в приёмнике ДО:   $DEST_FILES_BEFORE
  Файлов в приёмнике ПОСЛЕ: $DEST_FILES_AFTER
  НОВЫХ файлов добавлено:  $NEW_FILES
  Размер приёмника:        $DEST_SIZE

Код возврата rsync: $RSYNC_EXIT
(0 = успех, 23 = частичная ошибка)

Последние строки лога:
---------------------------------------------
$(tail -10 "$LOG_FILE" | sed 's/^/  /')
---------------------------------------------

Полный лог: $LOG_FILE

=============================================
С уважением,
система резервного копирования doc3files
============================================="

echo "Отправка отчета на $EMAIL_TO..." | tee -a "$LOG_FILE"
send_email "$SUBJECT" "$BODY"

echo "Письмо отправлено" | tee -a "$LOG_FILE"
echo "Лог сохранен: $LOG_FILE" | tee -a "$LOG_FILE"
echo "==================================================" | tee -a "$LOG_FILE"

cp "$LOG_FILE" "$REPORT_LOG" 2>/dev/null || true

exit $RSYNC_EXIT
