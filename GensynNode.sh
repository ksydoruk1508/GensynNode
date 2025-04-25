#!/bin/bash

# Цвета текста
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # Нет цвета (сброс цвета)

# Логотип
channel_logo() {
    echo -e "${GREEN}"
    cat << "EOF"
 ██████  ███████ ███    ██ ███████ ██    ██ ███    ██     ███    ██  ██████  ██████  ███████ 
██       ██      ████   ██ ██       ██  ██  ████   ██     ████   ██ ██    ██ ██   ██ ██      
██   ███ █████   ██ ██  ██ ███████   ████   ██ ██  ██     ██ ██  ██ ██    ██ ██   ██ █████   
██    ██ ██      ██  ██ ██      ██    ██    ██  ██ ██     ██  ██ ██ ██    ██ ██   ██ ██      
 ██████  ███████ ██   ████ ███████    ██    ██   ████     ██   ████  ██████  ██████  ███████ 
                                                                                             
________________________________________________________________________________________________________________________________________


███████  ██████  ██████      ██   ██ ███████ ███████ ██████      ██ ████████     ████████ ██████   █████  ██████  ██ ███    ██  ██████  
██      ██    ██ ██   ██     ██  ██  ██      ██      ██   ██     ██    ██           ██    ██   ██ ██   ██ ██   ██ ██ ████   ██ ██       
█████   ██    ██ ██████      █████   █████   █████   ██████      ██    ██           ██    ██████  ███████ ██   ██ ██ ██ ██  ██ ██   ███ 
██      ██    ██ ██   ██     ██  ██  ██      ██      ██          ██    ██           ██    ██   ██ ██   ██ ██   ██ ██ ██  ██ ██ ██    ██ 
██       ██████  ██   ██     ██   ██ ███████ ███████ ██          ██    ██           ██    ██   ██ ██   ██ ██████  ██ ██   ████  ██████  
                                                                                                                                         
                                                                                                                                        
 ██  ██████  ██       █████  ███    ██ ██████   █████  ███    ██ ████████ ███████                                                         
██  ██        ██     ██   ██ ████   ██ ██   ██ ██   ██ ████   ██    ██    ██                                                             
██  ██        ██     ███████ ██ ██  ██ ██   ██ ███████ ██ ██  ██    ██    █████                                                          
██  ██        ██     ██   ██ ██  ██ ██ ██   ██ ██   ██ ██  ██ ██    ██    ██                                                             
 ██  ██████  ██      ██   ██ ██   ████ ██████  ██   ██ ██   ████    ██    ███████

Donate: 0x0004230c13c3890F34Bb9C9683b91f539E809000                                                                              
EOF
    echo -e "${NC}"
}

# Проверка наличия curl и его установка, если отсутствует
check_curl() {
    if ! command -v curl &> /dev/null; then
        echo -e "${BLUE}Устанавливаем curl...${NC}" >&2
        sudo apt update && sudo apt install -y curl
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}curl успешно установлен.${NC}" >&2
        else
            echo -e "${RED}Не удалось установить curl! Выход...${NC}" >&2
            exit 1
        fi
    else
        echo -e "${GREEN}curl уже установлен.${NC}" >&2
    fi
}

# Функция установки ноды
download_node() {
    echo "Начинаю установку ноды..."
    cd "$HOME" || exit 1

    # Установка необходимых пакетов
    sudo apt update -y && sudo apt install -y lsof

    # Проверка портов
    local ports=(4040 3000 42763)
    for port in "${ports[@]}"; do
        if lsof -i :"$port" >/dev/null 2>&1; then
            echo "Ошибка: порт $port занят. Установка невозможна."
            exit 1
        fi
    done
    echo "Все порты свободны! Начинаю установку..."

    # Удаление старой ноды, если существует
    if [ -d "$HOME/rl-swarm" ]; then
        local pid
        pid=$(netstat -tulnp | grep :3000 | awk '{print $7}' | cut -d'/' -f1)
        [ -n "$pid" ] && sudo kill "$pid"
        sudo rm -rf "$HOME/rl-swarm"
    fi

    # Настройка swap
    local target_swap_gb=32
    local current_swap_kb
    current_swap_kb=$(free -k | awk '/Swap:/ {print $2}')
    local current_swap_gb=$((current_swap_kb / 1024 / 1024))

    echo "Текущий размер Swap: ${current_swap_gb}GB"
    if [ "$current_swap_gb" -lt "$target_swap_gb" ]; then
        swapoff -a
        sed -i '/swap/d' /etc/fstab
        local swapfile=/swapfile
        fallocate -l "${target_swap_gb}G" "$swapfile"
        chmod 600 "$swapfile"
        mkswap "$swapfile"
        swapon "$swapfile"
        echo "$swapfile none swap sw 0 0" >> /etc/fstab
        echo "vm.swappiness = 10" >> /etc/sysctl.conf
        sysctl -p
        echo "Swap установлен на ${target_swap_gb}GB"
    fi

    # Установка зависимостей
    sudo apt update -y && sudo apt upgrade -y
    sudo apt install -y git curl wget build-essential python3 python3-venv python3-pip screen yarn net-tools

    # Установка Node.js и Yarn
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt install -y nodejs
    sudo apt update
    curl -sSL https://raw.githubusercontent.com/zunxbt/installation/main/node.sh | bash

    # Клонирование и настройка
    git clone https://github.com/zunxbt/rl-swarm.git
    cd rl-swarm || exit 1
    python3 -m venv .venv
    source .venv/bin/activate
    pip install --upgrade pip

    # Настройка PyTorch
    read -p "На вашем сервере только CPU? (Y/N, если не знаете - Y): " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        echo "Настраиваю PyTorch для CPU..."
        export PYTORCH_ENABLE_MPS_FALLBACK=1
        export PYTORCH_MPS_HIGH_WATERMARK_RATIO=0.0
        sed -i 's/torch\.device("mps" if torch\.backends\.mps\.is_available() else "cpu")/torch.device("cpu")/g' hivemind_exp/trainer/hivemind_grpo_trainer.py
        echo "Настройка завершена."
    else
        echo "Оставляю настройки по умолчанию."
    fi

    # Очистка старого screen
    if screen -list | grep -q "gensyn"; then
        screen -ls | grep gensyn | awk '{print $1}' | cut -d'.' -f1 | xargs kill
    fi

    echo "Следуйте дальнейшим инструкциям в гайде."
}

# Функция запуска ноды
launch_node() {
    cd "$HOME/rl-swarm" || exit 1
    source .venv/bin/activate

    if screen -list | grep -q "gensyn"; then
        screen -ls | grep gensyn | awk '{print $1}' | cut -d'.' -f1 | xargs kill
    fi

    screen -S gensyn -d -m bash -c "trap '' INT; bash run_rl_swarm.sh 2>&1 | tee $HOME/rl-swarm/gensyn.log"
    echo "Нода запущена в screen 'gensyn'."
}

# Функция просмотра логов
watch_logs() {
    echo "Просмотр логов (Ctrl+C для возврата в меню)..."
    trap 'echo -e "\nВозврат в меню..."; return' SIGINT
    tail -n 100 -f "$HOME/rl-swarm/gensyn.log"
}

# Функция перехода в screen
go_to_screen() {
    echo "Выходите из screen через Ctrl+A + D"
    sleep 2
    screen -r gensyn
}

# Функция запуска локального сервера
open_local_server() {
    npm install -g localtunnel
    local server_ip
    server_ip=$(curl -s https://api.ipify.org || curl -s https://ifconfig.co/ip || dig +short myip.opendns.com @resolver1.opendns.com)

    read -p "Ваш IP: $server_ip. Это правильный IP? (y/n): " confirm
    if [[ "$confirm" != "y" ]]; then
        read -p "Введите ваш IP-адрес: " server_ip
    fi

    echo "Используется IP: $server_ip"
    ssh -L 3000:localhost:3000 "root@${server_ip}" &
    lt --port 3000
}

# Функция вывода данных пользователя
userdata() {
    cat "$HOME/rl-swarm/modal-login/temp-data/userData.json" 2>/dev/null || echo "Файл userData.json не найден."
}

# Функция вывода API ключа
userapikey() {
    cat "$HOME/rl-swarm/modal-login/temp-data/userApiKey.json" 2>/dev/null || echo "Файл userApiKey.json не найден."
}

# Функция остановки ноды
stop_node() {
    if screen -list | grep -q "gensyn"; then
        screen -ls | grep gensyn | awk '{print $1}' | cut -d'.' -f1 | xargs kill
    fi

    local pid
    pid=$(netstat -tulnp | grep :3000 | awk '{print $7}' | cut -d'/' -f1)
    [ -n "$pid" ] && sudo kill "$pid"
    echo "Нода остановлена."
}

# Функция удаления ноды
delete_node() {
    stop_node
    sudo rm -rf "$HOME/rl-swarm"
    echo "Нода удалена."
}

# Основной цикл меню
main_menu() {
    while true; do
        channel_logo
        sleep 2
        echo -e "\n\nМеню:"
        echo "1. Установить ноду"
        echo "2. Запустить ноду"
        echo "3. Посмотреть логи"
        echo "4. Перейти в screen ноды"
        echo "5. Запустить локальный сервер"
        echo "6. Показать данные пользователя"
        echo "7. Показать API ключ пользователя"
        echo "8. Остановить ноду"
        echo "9. Удалить ноду"
        echo "10. Выйти из скрипта"
        read -p "Выберите пункт меню: " choice

        case "$choice" in
            1) download_node ;;
            2) launch_node ;;
            3) watch_logs ;;
            4) go_to_screen ;;
            5) open_local_server ;;
            6) userdata ;;
            7) userapikey ;;
            8) stop_node ;;
            9) delete_node ;;
            10) exit 0 ;;
            *) echo "Неверный выбор. Введите число от 1 до 10." ;;
        esac
    done
}

# Запуск скрипта
main_menu
