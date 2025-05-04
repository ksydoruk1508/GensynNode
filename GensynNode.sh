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
    pip install hivemind==1.1.11
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
    # Создаем директорию, если она отсутствует
    mkdir -p "$HOME/rl-swarm"
    # Создаем или очищаем лог-файл
    touch "$HOME/rl-swarm/gensyn.log"
    : > "$HOME/rl-swarm/gensyn.log"

    cd "$HOME/rl-swarm" || exit 1
    source .venv/bin/activate

    # Определяем версию Python в виртуальной среде
    python_version=$(python --version 2>&1 | awk '{print $2}' | cut -d'.' -f1,2)
    site_packages_path="$HOME/rl-swarm/.venv/lib/python${python_version}/site-packages/transformers/trainer.py"

    # Проверяем существование файла trainer.py
    if [ -f "$site_packages_path" ]; then
        echo "Найден файл trainer.py для Python ${python_version}. Выполняю замену строки..."
        # Выполняем замену строки
        sed -i 's/torch\.cpu\.amp\.autocast(/torch.amp.autocast('"'"'cpu'"'"', /g' "$site_packages_path"
        if [ $? -eq 0 ]; then
            echo "Замена строки успешно выполнена в $site_packages_path"
        else
            echo "Ошибка при выполнении замены строки в $site_packages_path"
            exit 1
        fi
    else
        echo "Файл $site_packages_path не найден. Пропускаю замену строки."
    fi

    # Очистка существующего screen, если он есть
    if screen -list | grep -q "gensyn"; then
        screen -ls | grep gensyn | awk '{print $1}' | cut -d'.' -f1 | xargs kill
    fi

    # Запуск ноды в новом screen
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

# Функция исправления FutureWarning
fix_future_warning() {
    echo -e "${BLUE}Устраняю предупреждение FutureWarning: torch.cpu.amp.autocast...${NC}"

    # Остановка ноды
    echo -e "${YELLOW}Останавливаю ноду...${NC}"
    stop_node

    # Переход в директорию rl-swarm
    cd "$HOME/rl-swarm" || { echo -e "${RED}Не удалось войти в директорию rl-swarm. Убедитесь, что нода установлена.${NC}"; return; }

    # Активация виртуальной среды
    source .venv/bin/activate

    # Определяем версию Python в виртуальной среде
    python_version=$(python --version 2>&1 | awk '{print $2}' | cut -d'.' -f1,2)
    site_packages_path="$HOME/rl-swarm/.venv/lib/python${python_version}/site-packages/transformers/trainer.py"

    # Проверяем существование файла trainer.py
    if [ -f "$site_packages_path" ]; then
        echo -e "${YELLOW}Найден файл trainer.py для Python ${python_version}. Выполняю замену строки...${NC}"
        # Выполняем замену строки
        sed -i 's/torch\.cpu\.amp\.autocast(/torch.amp.autocast('"'"'cpu'"'"', /g' "$site_packages_path"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Замена строки успешно выполнена в $site_packages_path${NC}"
        else
            echo -e "${RED}Ошибка при выполнении замены строки в $site_packages_path${NC}"
            return
        fi
    else
        echo -e "${RED}Файл $site_packages_path не найден. Убедитесь, что пакет transformers установлен в виртуальной среде.${NC}"
        echo -e "${YELLOW}Попробуйте запустить ноду, чтобы установить зависимости, и повторите попытку.${NC}"
        return
    fi

    # Перезапуск ноды
    echo -e "${YELLOW}Перезапускаю ноду...${NC}"
    launch_node
}

# Функция исправления SyntaxError: duplicate argument 'bootstrap_timeout'
fix_bootstrap_timeout() {
    echo -e "${BLUE}Устраняю ошибку SyntaxError: duplicate argument 'bootstrap_timeout'...${NC}"

    # Остановка ноды
    echo -e "${YELLOW}Останавливаю ноду...${NC}"
    stop_node

    # Переход в директорию rl-swarm
    cd "$HOME/rl-swarm" || { echo -e "${RED}Не удалось войти в директорию rl-swarm. Убедитесь, что нода установлена.${NC}"; return; }

    # Активация виртуальной среды
    source .venv/bin/activate

    # Установка hivemind==1.1.11
    echo -e "${YELLOW}Устанавливаю hivemind==1.1.11...${NC}"
    pip install hivemind==1.1.11
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Установка hivemind==1.1.11 успешно завершена${NC}"
    else
        echo -e "${RED}Ошибка при установке hivemind==1.1.11${NC}"
        return
    fi

    # Перезапуск ноды
    echo -e "${YELLOW}Перезапускаю ноду...${NC}"
    launch_node
}

# Функция меню устранения неполадок
troubleshoot_menu() {
    while true; do
        echo -e "${BLUE}Меню устранения неполадок:${NC}"
        echo -e "${CYAN}1. Fix FutureWarning: torch.cpu.amp.autocast(args...) is deprecated${NC}"
        echo -e "${CYAN}2. Fix SyntaxError: duplicate argument 'bootstrap_timeout' in function definition${NC}"
        echo -e "${CYAN}3. Вернуться в главное меню${NC}"
        echo -e " "
        read -p "Введите номер: " choice

        case "$choice" in
            1) fix_future_warning ;;
            2) fix_bootstrap_timeout ;;
            3) return ;;
            *) echo "Неверный выбор. Введите число от 1 до 3." ;;
        esac
    done
}

# Функция обновления ноды
update_node() {
    echo -e "${BLUE}Начинаю обновление ноды...${NC}"
    
    # Создаем директорию, если она отсутствует
    mkdir -p "$HOME/rl-swarm"
    # Создаем или очищаем лог-файл
    touch "$HOME/rl-swarm/gensyn.log"
    : > "$HOME/rl-swarm/gensyn.log"
    
    # Остановка существующего screen gensyn
    pkill -f "SCREEN.*gensyn"
    
    # Сохранение существующих файлов swarm.pem, userData.json и userApiKey.json
    if [ -f "$HOME/rl-swarm/swarm.pem" ]; then
        cp "$HOME/rl-swarm/swarm.pem" "$HOME/"
        cp "$HOME/rl-swarm/modal-login/temp-data/userData.json" "$HOME/" 2>/dev/null
        cp "$HOME/rl-swarm/modal-login/temp-data/userApiKey.json" "$HOME/" 2>/dev/null
    fi

    # Удаление старой директории и клонирование новой
    rm -rf "$HOME/rl-swarm"
    cd "$HOME" && git clone https://github.com/zunxbt/rl-swarm.git > /dev/null 2>&1
    cd "$HOME/rl-swarm" || { echo -e "${RED}Failed to enter rl-swarm directory. Exiting.${NC}"; exit 1; }

    # Восстановление сохраненных файлов
    if [ -f "$HOME/swarm.pem" ]; then
        mv "$HOME/swarm.pem" "$HOME/rl-swarm/"
        mv "$HOME/userData.json" "$HOME/rl-swarm/modal-login/temp-data/" 2>/dev/null
        mv "$HOME/userApiKey.json" "$HOME/rl-swarm/modal-login/temp-data/" 2>/dev/null
    fi

    # Настройка виртуальной среды
    if [ -n "$VIRTUAL_ENV" ]; then
        deactivate
    fi
    python3 -m venv .venv
    source .venv/bin/activate

    # Определяем версию Python в виртуальной среде
    python_version=$(python --version 2>&1 | awk '{print $2}' | cut -d'.' -f1,2)
    site_packages_path="$HOME/rl-swarm/.venv/lib/python${python_version}/site-packages/transformers/trainer.py"

    # Проверяем существование файла trainer.py
    if [ -f "$site_packages_path" ]; then
        echo -e "${YELLOW}Найден файл trainer.py для Python ${python_version}. Выполняю замену строки...${NC}"
        sed -i 's/torch\.cpu\.amp\.autocast(/torch.amp.autocast('"'"'cpu'"'"', /g' "$site_packages_path"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Замена строки успешно выполнена в $site_packages_path${NC}"
        else
            echo -e "${RED}Ошибка при выполнении замены строки в $site_packages_path${NC}"
            exit 1
        fi
    else
        echo -e "${YELLOW}Файл $site_packages_path не найден. Пропускаю замену строки.${NC}"
    fi

    # Запуск ноды в screen
    screen -S gensyn -d -m bash -c "trap '' INT; bash run_rl_swarm.sh 2>&1 | tee $HOME/rl-swarm/gensyn.log"
    echo -e "${GREEN}Обновление завершено. Нода запущена в screen 'gensyn'. Логи доступны в $HOME/rl-swarm/gensyn.log${NC}"
}

# Основной цикл меню
main_menu() {
    while true; do
        channel_logo
        sleep 2
        echo -e  "${YELLOW}Выберите действие:${NC}"
        echo -e "${CYAN}1. Установить ноду (v. 0.4.2)${NC}"
        echo -e "${CYAN}2. Запустить ноду${NC}"
        echo -e "${CYAN}3. Посмотреть логи${NC}"
        echo -e "${CYAN}4. Перейти в screen ноды${NC}"
        echo -e "${CYAN}5. Запустить локальный сервер${NC}"
        echo -e "${CYAN}6. Показать данные пользователя${NC}"
        echo -e "${CYAN}7. Показать API ключ пользователя${NC}"
        echo -e "${CYAN}8. Остановить ноду${NC}"
        echo -e "${CYAN}9. Удалить ноду${NC}"
        echo -e "${CYAN}10. Обновить ноду (v. 0.4.2)${NC}"
        echo -e "${CYAN}11. Выйти из скрипта${NC}"
        echo -e "${CYAN}12. Устранить неполадки${NC}"
        echo -e " "
        read -p "Введите номер: " choice

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
            10) update_node ;;
            11) exit 0 ;;
            12) troubleshoot_menu ;;
            *) echo "Неверный выбор. Введите число от 1 до 12." ;;
        esac
    done
}

# Запуск скрипта
main_menu
