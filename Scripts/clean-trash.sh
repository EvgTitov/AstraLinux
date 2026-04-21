#!/bin/bash

# =============================================================================
# Скрипт очистки корзин файлового сервера Samba
# Назначение: Удаление файлов старше N дней и контроль размера корзины
# ОС: Astra Linux
# Версия: 1.0
# =============================================================================

# === НАСТРОЙКИ ===
# Количество дней хранения файлов в корзине
DAYS=30

# Максимальный размер корзины в гигабайтах
MAX_SIZE_GB=100

# === ВЫЧИСЛЕНИЯ ===
# Переводим дни в минуты
MINUTES=$((DAYS * 24 * 60))

# Переводим гигабайты в байты
MAX_SIZE_BYTES=$((MAX_SIZE_GB * 1024 * 1024 * 1024))

# Лог-файл
LOG_FILE="/var/log/trash-cleanup.log"

# === ФУНКЦИЯ СОЗДАНИЯ ПАПОК ===
create_trash_folder() {
    local folder="$1"
    local name="$2"
    local gid="$3"
    
    if [ ! -d "$folder" ]; then
        mkdir -p "$folder"
        chown root:"$gid" "$folder"
        chmod 0770 "$folder"
        setfacl -m g:"$gid":rwx "$folder"
        setfacl -d -m g:"$gid":rwx "$folder"
        echo "$(date): Создана папка $folder с правами для группы $gid" >> "$LOG_FILE"
    fi
}

# === ФУНКЦИЯ ОЧИСТКИ ОДНОЙ КОРЗИНЫ ===
clean_trash_folder() {
    local folder="$1"
    local name="$2"
    
    if [ ! -d "$folder" ]; then
        echo "$(date): Папка $folder не существует" >> "$LOG_FILE"
        return
    fi
    
    echo "$(date): ===== Начало очистки $name =====" >> "$LOG_FILE"
    
    # Получаем текущий размер
    current_size_bytes=$(du -sb "$folder" 2>/dev/null | cut -f1)
    [ -z "$current_size_bytes" ] && current_size_bytes=0
    current_size_gb=$((current_size_bytes / 1024 / 1024 / 1024))
    
    echo "$(date): Текущий размер корзины $name: ${current_size_gb}GB" >> "$LOG_FILE"
    
    # 1. Удаляем файлы старше DAYS дней
    old_files=$(find "$folder" -type f -mmin +$MINUTES 2>/dev/null | wc -l)
    find "$folder" -type f -mmin +$MINUTES -delete 2>/dev/null
    echo "$(date): Удалено старых файлов (старше $DAYS дней): $old_files" >> "$LOG_FILE"
    
    # 2. Удаляем пустые подпапки (но не саму папку Trash)
    find "$folder" -mindepth 1 -type d -empty -delete 2>/dev/null
    
    # 3. Проверяем размер после удаления старых файлов
    current_size_bytes=$(du -sb "$folder" 2>/dev/null | cut -f1)
    [ -z "$current_size_bytes" ] && current_size_bytes=0
    current_size_gb=$((current_size_bytes / 1024 / 1024 / 1024))
    
    echo "$(date): Размер после удаления старых файлов: ${current_size_gb}GB" >> "$LOG_FILE"
    
    # 4. Если размер превышает лимит — удаляем самые старые файлы
    if [ "$current_size_bytes" -gt "$MAX_SIZE_BYTES" ]; then
        echo "$(date): ВНИМАНИЕ! Размер превышает лимит ${MAX_SIZE_GB}GB" >> "$LOG_FILE"
        
        deleted_count=0
        while [ "$current_size_bytes" -gt "$MAX_SIZE_BYTES" ]; do
            # Находим самый старый файл
            oldest_file=$(find "$folder" -type f -printf '%T@ %p\n' 2>/dev/null | sort -n | head -1 | cut -d' ' -f2-)
            [ -z "$oldest_file" ] && break
            rm -f "$oldest_file"
            deleted_count=$((deleted_count + 1))
            current_size_bytes=$(du -sb "$folder" 2>/dev/null | cut -f1)
            [ -z "$current_size_bytes" ] && current_size_bytes=0
        done
        
        echo "$(date): Принудительно удалено файлов: $deleted_count" >> "$LOG_FILE"
        current_size_gb=$((current_size_bytes / 1024 / 1024 / 1024))
        echo "$(date): Новый размер: ${current_size_gb}GB" >> "$LOG_FILE"
    else
        echo "$(date): Размер в пределах лимита (${MAX_SIZE_GB}GB)" >> "$LOG_FILE"
    fi
    
    # 5. Еще раз удаляем пустые подпапки
    find "$folder" -mindepth 1 -type d -empty -delete 2>/dev/null
    
    echo "$(date): ===== Очистка $name завершена =====" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
}

# === ГЛАВНАЯ ПРОГРАММА ===

echo "$(date): ========== ЗАПУСК ОЧИСТКИ ==========" >> "$LOG_FILE"

# Создаем папки Trash если их нет (GID группы ad7 = 16312)
create_trash_folder "/mnt/Smeta/Trash" "Smeta" "16312"
create_trash_folder "/mnt/Ten/Trash" "Ten" "16312"
create_trash_folder "/mnt/PU/Trash" "PU" "16312"
create_trash_folder "/mnt/U/Trash" "U" "16312"

# Очищаем корзины
clean_trash_folder "/mnt/Smeta/Trash" "Smeta"
clean_trash_folder "/mnt/Ten/Trash" "Ten"
clean_trash_folder "/mnt/PU/Trash" "PU"
clean_trash_folder "/mnt/U/Trash" "U"

echo "$(date): ========== ОБЩАЯ ОЧИСТКА ЗАВЕРШЕНА ==========" >> "$LOG_FILE"
echo "----------------------------------------" >> "$LOG_FILE"

exit 0
