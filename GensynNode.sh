#!/bin/bash

# Переменные для проверки версии
SCRIPT_NAME="Gensyn"
SCRIPT_VERSION="1.2.0"
VERSIONS_FILE_URL="https://raw.githubusercontent.com/k2wGG/scripts/main/versions.txt"
SCRIPT_FILE_URL="https://raw.githubusercontent.com/k2wGG/scripts/main/Gensyn.sh"

# Цвета для вывода
clrGreen='\033[0;32m'
clrCyan='\033[0;36m'
clrRed='\033[0;31m'
clrYellow='\033[1;33m'
clrReset='\033[0m'
clrBold='\033[1m'

print_ok()    { echo -e "${clrGreen}[OK] $1${clrReset}"; }
print_info()  { echo -e "${clrCyan}[INFO] $1${clrReset}"; }
print_warn()  { echo -e "${clrYellow}[WARN] $1${clrReset}"; }
print_error() { echo -e "${clrRed}[ERROR] $1${clrReset}"; }

display_logo() {
    cat <<'EOF'
 _   _           _  _____      
| \ | |         | ||____ |     
|  \| | ___   __| |    / /_ __ 
| . ` |/ _ \ / _` |    \ \ '__|
| |\  | (_) | (_| |.___/ / |   
\_| \_/\___/ \__,_|\____/|_|
          Gensyn
           Канал: @nod3r
EOF
}

check_script_version() {
    print_info "Проверка актуальности скрипта..."
    remote_version=$(curl -s "$VERSIONS_FILE_URL" | grep "^${SCRIPT_NAME}=" | cut -d'=' -f2)
    if [ -z "$remote_version" ]; then
        print_warn "Не удалось определить удалённую версию для ${SCRIPT_NAME}"
    elif [ "$remote_version" != "$SCRIPT_VERSION" ]; then
        print_warn "Доступна новая версия: $remote_version (текущая: $SCRIPT_VERSION)"
        print_info "Рекомендуется скачать обновлённый скрипт отсюда:\n$SCRIPT_FILE_URL"
    else
        print_ok "Используется актуальная версия скрипта ($SCRIPT_VERSION)"
    fi
}

# Убрана проверка версий Python и Node.js

system_update_and_install() {
    print_info "Обновление системы и установка необходимых инструментов разработки..."
    
    sudo apt update
    sudo apt install -y python3 python3-venv python3-pip curl screen git
    
    # Установка yarn из официального репозитория
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
    sudo apt update && sudo apt install -y yarn
    
    # Установка localtunnel
    sudo npm install -g localtunnel
    
    # Установка Node.js 22.x
    sudo apt-get update
    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
    sudo apt-get install -y nodejs
    
    # Проверка версий
    node -v
    sudo npm install -g yarn
    yarn -v
    
    print_ok "Все зависимости установлены"
}

clone_repo() {
    print_info "Клонирование репозитория RL Swarm..."
    git clone https://github.com/gensyn-ai/rl-swarm.git "$HOME/rl-swarm" || { print_error "Не удалось клонировать репозиторий"; exit 1; }
    print_ok "Репозиторий клонирован"
}

start_gensyn_screen() {
    # Проверка и запуск screen-сессии gensyn для узла
    if screen -list | grep -q "gensyn"; then
        print_warn "Screen-сессия 'gensyn' уже существует! Используйте 'screen -r gensyn' для входа."
        return
    fi
    print_info "Запускаю RL Swarm node в screen-сессии 'gensyn'..."
    screen -dmS gensyn bash -c '
        cd ~/rl-swarm || exit 1
        python3 -m venv .venv
        source .venv/bin/activate
        pip install --force-reinstall trl==0.19.1
        ./run_rl_swarm.sh
        while true; do
            sleep 60
        done
    '
    print_ok "Узел запущен в screen-сессии 'gensyn'. Введите 'screen -r gensyn' для подключения."
}

update_node() {
    print_info "Обновление RL Swarm..."
    if [ -d "$HOME/rl-swarm" ]; then
        cd "$HOME/rl-swarm" || exit 1
        git switch main
        git reset --hard
        git clean -fd
        git pull origin main
        git pull
        print_ok "Репозиторий обновлён."
    else
        print_error "Папка rl-swarm не найдена"
    fi
}

check_current_node_version() {
    if [ -d "$HOME/rl-swarm" ]; then
        cd "$HOME/rl-swarm" || { print_error "Не удалось перейти в директорию rl-swarm"; return; }
        current_version=$(git describe --tags 2>/dev/null)
        if [ $? -eq 0 ]; then
            print_ok "Текущая версия ноды: $current_version"
        else
            print_warn "Не удалось определить текущую версию (возможно, нет тегов)"
        fi
    else
        print_error "Папка rl-swarm не найдена"
    fi
}

delete_rlswarm() {
    print_warn "Сохраняю приватник swarm.pem (если есть)..."
    if [ -f "$HOME/rl-swarm/swarm.pem" ]; then
        cp "$HOME/rl-swarm/swarm.pem" "$HOME/swarm.pem.backup"
        print_ok "swarm.pem скопирован в $HOME/swarm.pem.backup"
    fi
    print_info "Удаляю rl-swarm..."
    rm -rf "$HOME/rl-swarm"
    print_ok "Папка rl-swarm удалена. Приватник сохранён как ~/swarm.pem.backup"
}

restore_swarm_pem() {
    if [ -f "$HOME/swarm.pem.backup" ]; then
        cp "$HOME/swarm.pem.backup" "$HOME/rl-swarm/swarm.pem"
        print_ok "swarm.pem восстановлен из $HOME/swarm.pem.backup"
    else
        print_warn "Бэкап swarm.pem не найден."
    fi
}

setup_cloudflared_screen() {
    print_info "Установка и запуск Cloudflared для HTTPS-туннеля на порт 3000..."

    # Базовые пакеты
    sudo apt-get update -y
    sudo apt-get install -y ufw screen wget ca-certificates

    # UFW правила
    sudo ufw allow 22/tcp
    sudo ufw allow 3000/tcp
    sudo ufw --force enable

    # Определяем архитектуру для выбора правильного .deb
    local ARCH
    ARCH="$(dpkg --print-architecture 2>/dev/null || echo unknown)"

    local DEB_URL=""
    case "$ARCH" in
        amd64)
            DEB_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb"
            ;;
        arm64)
            DEB_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64.deb"
            ;;
        *)
            print_err "Неподдерживаемая архитектура: ${ARCH}. Поддерживаются amd64 и arm64."
            return 1
            ;;
    esac

    # Установка cloudflared, если не стоит
    if ! command -v cloudflared >/dev/null 2>&1; then
        print_info "cloudflared не найден. Скачиваю пакет для ${ARCH}..."
        local TMP_DEB="/tmp/cloudflared-${ARCH}.deb"
        if ! wget -q -O "${TMP_DEB}" "${DEB_URL}"; then
            print_err "Не удалось скачать cloudflared для ${ARCH}."
            return 1
        fi

        print_info "Устанавливаю cloudflared..."
        if ! sudo dpkg -i "${TMP_DEB}" >/dev/null 2>&1; then
            # подтянуть зависимости при необходимости
            sudo apt-get -f install -y
            # повторить установку
            sudo dpkg -i "${TMP_DEB}" >/dev/null 2>&1 || {
                print_err "Не удалось установить cloudflared для ${ARCH}."
                rm -f "${TMP_DEB}"
                return 1
            }
        fi
        rm -f "${TMP_DEB}"
    fi

    # Финальная проверка наличия бинаря
    if ! command -v cloudflared >/dev/null 2>&1; then
        print_err "cloudflared не найден после установки. Прерываю."
        return 1
    fi

    # Не создаём второй screen, если уже есть
    if screen -list | grep -q "[.]cftunnel"; then
        print_warn "Screen-сессия 'cftunnel' уже существует! Используйте 'screen -r cftunnel' для входа."
        return 0
    fi

    # Папка для логов
    sudo mkdir -p /var/log
    local LOG_FILE="/var/log/cloudflared-screen.log"

    print_info "Запускаю Cloudflared tunnel в screen-сессии 'cftunnel'..."
    # -dmS: detached, named session; bash -lc чтобы подхватить PATH
    screen -dmS cftunnel bash -lc "cloudflared tunnel --no-autoupdate --url http://localhost:3000 2>&1 | tee -a ${LOG_FILE}"

    # Небольшая задержка и проверка процесса
    sleep 1
    if pgrep -af cloudflared >/dev/null 2>&1; then
        print_ok "Cloudflared-туннель запущен в screen 'cftunnel'. Ссылку смотри в выводе: 'screen -r cftunnel'. Логи: ${LOG_FILE}"
        return 0
    else
        print_err "Не удалось запустить cloudflared в screen. Проверь логи: ${LOG_FILE} и 'screen -r cftunnel'."
        return 1
    fi
}

swap_menu() {
    while true; do
        clear
        display_logo
        echo -e "\n${clrBold}Управление файлом подкачки:${clrReset}"
        echo "1) Активный файл подкачки в данный момент"
        echo "2) Остановка файла подкачки"
        echo "3) Создание файла подкачки"
        echo "4) Назад"
        read -rp "Введите номер: " swap_choice
        case $swap_choice in
            1)
                print_info "Активный файл подкачки:"
                swapon --show
                ;;
            2)
                print_info "Остановка файла подкачки..."
                if [ -f /swapfile ]; then
                    sudo swapoff /swapfile
                    print_ok "Файл подкачки остановлен"
                else
                    print_warn "Файл подкачки /swapfile не найден"
                fi
                ;;
            3)
                read -rp "Введите размер файла подкачки в ГБ: " swap_size
                if [[ $swap_size =~ ^[0-9]+$ ]] && [ "$swap_size" -gt 0 ]; then
                    print_info "Создание файла подкачки размером ${swap_size}ГБ..."
                    sudo fallocate -l ${swap_size}G /swapfile
                    sudo mkswap /swapfile
                    sudo swapon /swapfile
                    print_ok "Файл подкачки размером ${swap_size}ГБ создан и активирован"
                else
                    print_error "Неверный размер. Введите положительное целое число."
                fi
                ;;
            4)
                return
                ;;
            *)
                print_error "Неверный выбор, попробуйте снова."
                ;;
        esac
        echo -e "\nНажмите Enter для возврата в меню..."
        read -r
    done
}

main_menu() {
    while true; do
        clear
        display_logo
        check_script_version
        echo -e "\n${clrBold}Выберите действие:${clrReset} / Select an action:"
        echo "1) Установить зависимости / Install dependencies"
        echo "2) Клонировать RL Swarm / Clone RL Swarm"
        echo "3) Запустить узел Gensyn в screen (название: gensyn) / Run Gensyn node in screen (name: gensyn)"
        echo "4) Обновить RL Swarm / Update RL Swarm"
        echo "5) Проверка текущей версии ноды / Check current node version"
        echo "6) Удалить RL Swarm (сохранить приватник) / Remove RL Swarm (keep private key)"
        echo "7) Восстановить swarm.pem из бэкапа / Restore swarm.pem from backup"
        echo "8) Запустить HTTPS-туннель Cloudflared (screen: cftunnel) / Start HTTPS tunnel Cloudflared (screen: cftunnel)"
        echo "9) Управление файлом подкачки / Swap file management"
        echo "10) Выход / Exit"
        read -rp "Введите номер / Enter a number: " choice
        case $choice in
            1) system_update_and_install ;;
            2) clone_repo ;;
            3) start_gensyn_screen ;;
            4) update_node ;;
            5) check_current_node_version ;;
            6) delete_rlswarm ;;
            7) restore_swarm_pem ;;
            8) setup_cloudflared_screen ;;
            9) swap_menu ;;
            10) echo -e "${clrGreen}До свидания!${clrReset}"; exit 0 ;;
            *) print_error "Неверный выбор, попробуйте снова." ;;
        esac
        echo -e "\nНажмите Enter для возврата в меню..."
        read -r
    done
}

# Запуск главного меню (без проверки версий)
main_menu
