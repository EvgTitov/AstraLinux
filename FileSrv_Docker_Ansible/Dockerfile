FROM ubuntu:22.04

# Неинтерактивная установка
ENV DEBIAN_FRONTEND=noninteractive

# Часовой пояс по умолчанию
ENV TZ=Europe/Moscow


RUN apt-get update && \
    apt-get install -y \
    tzdata \
    ansible \
    samba \
    samba-client \
    winbind \
    krb5-user \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install pywinrm dnspython

COPY samba-playbook.yml /ansible/
COPY templates/ /ansible/templates/
COPY files/ /ansible/files/

# Директории для общих папок и права
RUN mkdir -p /srv/samba/shared_folder /mnt/new1 /mnt/new2 && \
    # Создаём пользователя nobody, если его нет
    useradd nobody 2>/dev/null || true && \
    # Устанавливаем владельца nobody:nogroup для всех директорий Samba
    chown -R nobody:nogroup /srv/samba /mnt && \
    # Устанавливаем права 777 для возможности записи
    chmod -R 777 /srv/samba /mnt

# Копируем smb.conf
COPY files/smb.conf /etc/samba/smb.conf

WORKDIR /ansible

CMD ["sh", "-c", "service smbd start && service nmbd start && service winbind start && tail -f /dev/null"]
