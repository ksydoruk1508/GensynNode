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

# Функция обновления системы и установки базовых пакетов
system_update() {
    echo -e "${BLUE}Обновление системы и установка необходимых пакетов...${NC}" >&2
    sudo apt-get update && sudo apt-get upgrade -y
    sudo apt-get install -y curl build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip python3 python3-pip
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Базовые пакеты успешно установлены.${NC}" >&2
    else
        echo -e "${RED}Не удалось установить базовые пакеты! Выход...${NC}" >&2
        return 1
    fi
}

# Определение команды для работы с Docker Compose
set_dc_command() {
    if docker compose version &> /dev/null; then
        DC="docker compose"
    else
        DC="docker-compose"
    fi
    echo -e "${GREEN}Используется команда: $DC${NC}" >&2
}

# Функция установки Docker и Docker Compose
install_docker() {
    echo -e "${BLUE}Проверка наличия Docker...${NC}" >&2
    if ! command -v docker &> /dev/null; then
        echo -e "${YELLOW}Docker не найден, устанавливаем...${NC}" >&2
        sudo apt-get install -y docker.io
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Docker успешно установлен.${NC}" >&2
        else
            echo -e "${RED}Не удалось установить Docker! Выход...${NC}" >&2
            return 1
        fi
    else
        echo -e "${GREEN}Docker уже установлен.${NC}" >&2
    fi

    echo -e "${BLUE}Проверка наличия Docker Compose...${NC}" >&2
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${YELLOW}Docker Compose не найден, устанавливаем...${NC}" >&2
        sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Docker Compose успешно установлен.${NC}" >&2
        else
            echo -e "${RED}Не удалось установить Docker Compose! Выход...${NC}" >&2
            return 1
        fi
    else
        echo -e "${GREEN}Docker Compose уже установлен.${NC}" >&2
    fi

    set_dc_command
    sudo usermod -aG docker $USER
    echo -e "${GREEN}Пользователь добавлен в группу docker.${NC}" >&2
}

# Функция создания файла docker-compose.yml
generate_compose() {
    echo -e "${BLUE}Генерация файла docker-compose.yml...${NC}" >&2
    [ -f docker-compose.yml ] && mv docker-compose.yml docker-compose.yml.bak
    cat << 'EOF' > docker-compose.yml
version: '3'

services:
  collector:
    image: otel/opentelemetry-collector-contrib:0.120.0
    ports:
      - "4317:4317"
      - "4318:4318"
      - "55679:55679"
    environment:
      - OTEL_LOG_LEVEL=DEBUG

  node:
    image: europe-docker.pkg.dev/gensyn-public-b7d9/public/rl-swarm:v0.0.2
    command: ./run_hivemind_docker.sh
    environment:
      - OTEL_EXPORTER_OTLP_ENDPOINT=http://collector:4317
      - PEER_MULTI_ADDRS=/ip4/38.101.215.13/tcp/30002/p2p/QmQ2gEXoPJg6iMBSUFWGzAabS2VhnzuS782Y637hGjfsRJ
      - HOST_MULTI_ADDRS=/ip4/0.0.0.0/tcp/38331
    ports:
      - "38331:38331"
    depends_on:
      - collector

  web:
    build:
      context: .
      dockerfile: Dockerfile.webserver
    environment:
      - OTEL_SERVICE_NAME=rlswarm-web
      - OTEL_EXPORTER_OTLP_ENDPOINT=http://collector:4317
      - INITIAL_PEERS=/ip4/38.101.215.13/tcp/30002/p2p/QmQ2gEXoPJg6iMBSUFWGzAabS2VhnzuS782Y637hGjfsRJ
    ports:
      - "8177:8000"
    depends_on:
      - collector
      - node
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/api/healthz"]
      interval: 30s
      retries: 3
EOF
    echo -e "${GREEN}Файл docker-compose.yml успешно создан.${NC}" >&2
}

# Функция запуска узла
start_node() {
    echo -e "${BLUE}Запуск узла Gensyn...${NC}" >&2
    system_update
    install_docker
    echo -e "${BLUE}Клонирование репозитория...${NC}" >&2
    git clone https://github.com/gensyn-ai/rl-swarm/ || { echo -e "${RED}Не удалось клонировать репозиторий!${NC}" >&2; return 1; }
    cd rl-swarm || { echo -e "${RED}Не удалось перейти в директорию rl-swarm!${NC}" >&2; return 1; }
    generate_compose
    $DC pull
    $DC up -d
    echo -e "${GREEN}Узел Gensyn успешно запущен.${NC}" >&2
    echo -e "${BLUE}Показываем логи узла...${NC}" >&2
    $DC logs node
}

# Функция обновления узла
update_node() {
    echo -e "${BLUE}Обновление узла Gensyn...${NC}" >&2
    if [ ! -d "$HOME/rl-swarm" ]; then
        echo -e "${RED}Папка узла не найдена. Сначала запустите узел.${NC}" >&2
        return 1
    fi
    cd "$HOME/rl-swarm" || { echo -e "${RED}Не удалось перейти в директорию $HOME/rl-swarm!${NC}" >&2; return 1; }
    set_dc_command
    new_image="rl-swarm:v0.0.2"
    sed -i "s#\(image: europe-docker.pkg.dev/gensyn-public-b7d9/public/\).*#\1${new_image}#g" docker-compose.yml
    $DC pull
    $DC up -d --force-recreate
    echo -e "${GREEN}Узел успешно обновлён до версии ${new_image}.${NC}" >&2
    echo -e "${BLUE}Показываем логи узла...${NC}" >&2
    $DC logs node
}

# Функция просмотра логов
show_logs() {
    echo -e "${BLUE}Просмотр логов узла Gensyn (последние 100 строк в реальном времени)...${NC}" >&2
    echo -e "${YELLOW}Нажмите Ctrl+C для возврата в меню${NC}" >&2
    if [ ! -d "$HOME/rl-swarm" ]; then
        echo -e "${RED}Папка узла не найдена. Сначала запустите узел.${NC}" >&2
        return 1
    fi
    cd "$HOME/rl-swarm" || { echo -e "${RED}Не удалось перейти в директорию $HOME/rl-swarm!${NC}" >&2; return 1; }
    set_dc_command
    # Запускаем логи с tail в реальном времени
    trap 'echo -e "${BLUE}Возвращаемся в меню...${NC}" >&2; return' INT
    $DC logs -f node | tail -n 100
}

# Функция перезапуска узла
restart_node() {
    echo -e "${BLUE}Перезапуск узла Gensyn...${NC}" >&2
    if [ ! -d "$HOME/rl-swarm" ]; then
        echo -e "${RED}Папка узла не найдена. Сначала запустите узел.${NC}" >&2
        return 1
    fi
    cd "$HOME/rl-swarm" || { echo -e "${RED}Не удалось перейти в директорию $HOME/rl-swarm!${NC}" >&2; return 1; }
    set_dc_command
    $DC restart
    echo -e "${GREEN}Узел успешно перезапущен.${NC}" >&2
    echo -e "${BLUE}Показываем логи узла...${NC}" >&2
    $DC logs node
}

# Функция удаления узла
delete_node() {
    echo -e "${BLUE}Удаление узла Gensyn...${NC}" >&2
    if [ ! -d "$HOME/rl-swarm" ]; then
        echo -e "${YELLOW}Папка узла не обнаружена. Возможно, узел уже удалён.${NC}" >&2
        return
    fi
    cd "$HOME/rl-swarm" || { echo -e "${RED}Не удалось перейти в директорию $HOME/rl-swarm!${NC}" >&2; return 1; }
    set_dc_command
    $DC down -v
    cd "$HOME"
    rm -rf "$HOME/rl-swarm"
    echo -e "${GREEN}Узел Gensyn успешно удалён.${NC}" >&2
}

# Функция выхода из скрипта
exit_from_script() {
    echo -e "${BLUE}Выход из скрипта...${NC}" >&2
    exit 0
}

# Главное меню
main_menu() {
    while true; do
        clear
        channel_logo
        echo -e "\n\n${YELLOW}Выберите действие:${NC}" >&2
        echo -e "${CYAN}1. Установить ноду${NC}" >&2
        echo -e "${CYAN}2. Обновить ноду${NC}" >&2
        echo -e "${CYAN}3. Просмотреть логи${NC}" >&2
        echo -e "${CYAN}4. Перезапустить ноду${NC}" >&2
        echo -e "${CYAN}5. Удалить ноду${NC}" >&2
        echo -e "${CYAN}6. Выход${NC}" >&2
        
        echo -e "${YELLOW}Введите номер:${NC} " >&2
        if [ -t 0 ] && [ -t 1 ]; then
            read choice
        else
            echo -e "${RED}Неинтерактивный режим: выбор невозможен. Выход...${NC}" >&2
            exit 1
        fi
        case $choice in
            1) start_node ;;
            2) update_node ;;
            3) show_logs ;;
            4) restart_node ;;
            5) delete_node ;;
            6) exit_from_script ;;
            *) echo -e "${RED}Неверный выбор, попробуйте снова.${NC}" >&2 ;;
        esac
    done
}

# Проверка curl перед началом работы
check_curl

# Запуск главного меню
main_menu
