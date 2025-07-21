#!/bin/bash

set -e

# Цвета
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Функция установки ноды
install_node() {
    echo -e "${YELLOW}Обновление системы и установка зависимостей...${NC}"
    sudo apt update && sudo apt upgrade -y

    sudo apt install -y screen curl iptables build-essential git wget lz4 jq make gcc nano \
    automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar \
    clang bsdmainutils ncdu unzip libleveldb-dev python3-venv python3-pip python3-dev

    echo -e "${YELLOW}Добавление Yarn и установка Node.js 22...${NC}"
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo gpg --dearmor -o /usr/share/keyrings/yarnkey.gpg
    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
    sudo apt-get install -y nodejs
    sudo npm install -g yarn

    echo -e "${GREEN}Node.js версия: $(node -v)${NC}"
    echo -e "${GREEN}Yarn версия: $(yarn -v)${NC}"
    sudo npm install -g localtunnel

    echo -e "${YELLOW}Клонируем репозиторий rl-swarm...${NC}"
    rm -rf rl-swarm && git clone https://github.com/gensyn-ai/rl-swarm/ && cd rl-swarm
    echo -e "${GREEN}Установка завершена.${NC}"
}

# Функция запуска ноды и отображения логов
run_node() {
    echo -e "${YELLOW}Запуск ноды...${NC}"
    cd "$HOME/rl-swarm" || { echo "Папка rl-swarm не найдена!"; exit 1; }

    python3 -m venv .venv
    source .venv/bin/activate

    nohup bash -c "source .venv/bin/activate && ./run_rl_swarm.sh" > run.log 2>&1 &

    echo -e "${GREEN}Нода запущена через nohup. Открываю логи...${NC}"
    sleep 2
    tail -n 50 -f run.log
}

# Меню
while true; do
    echo -e "${CYAN}"
    echo "======================"
    echo "    RL-SWARM MENU2     "
    echo "======================"
    echo -e "${NC}"
    echo "1. Установить ноду"
    echo "2. Запустить ноду и смотреть логи"
    echo "3. Выйти"
    echo ""
    read -p "Выберите действие [1-3]: " choice

    case "$choice" in
        1) install_node ;;
        2) run_node ;;
        3) echo "Выход..."; exit 0 ;;
        *) echo "Неверный выбор. Введите 1, 2 или 3." ;;
    esac
    echo ""
done
