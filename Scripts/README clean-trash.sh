# Samba Trash Cleanup Script

Скрипт для автоматической очистки корзин на файловом сервере Samba (Astra Linux)
Создан по большей степени для Astra Linux т.к в ней не работают квоты на подпапки в файловой системе Samba
Разработан для домена АО "Казанский Гипронииавиапром" им. Б. И. Тихомирова
Для работоспособности в других доменах  нужно менять параметры групп домена и пути к папкам
## Функционал

- Удаление файлов старше N дней (по умолчанию 30)
- Контроль максимального размера корзины (по умолчанию 100 ГБ)
- Автоматическое создание папок Trash с правильными правами
- Подробное логирование всех действий
- Защита папок Trash от случайного удаления

## Установка

```bash
# Скачать скрипт
sudo wget -O /usr/local/bin/clean-trash.sh https://raw.githubusercontent.com/your-repo/clean-trash.sh
# или скопировать вручную

# Сделать исполняемым
sudo chmod +x /usr/local/bin/clean-trash.sh

# Настроить crontab (ежедневно в 00:00)
sudo crontab -e
# Добавить строку:
0 0 * * * /usr/local/bin/clean-trash.sh

# Алиас для просмотра статистики
echo 'alias trash-stats="echo \"=== Размер корзин ===\" && sudo du -sh /mnt/*/Trash 2>/dev/null && echo \"\" && echo \"=== Последние очистки ===\" && sudo tail -10 /var/log/trash-cleanup.log"' >> ~/.bashrc
source ~/.bashrc

# Просмотр логов
sudo tail -f /var/log/trash-cleanup.log
