#!/bin/bash

set -e

# Цвета
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}Обновление системы и установка зависимостей...${NC}"
sudo apt update && sudo apt upgrade -y

sudo apt install -y screen curl iptables build-essential git wget lz4 jq make gcc nano \
automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar \
clang bsdmainutils ncdu unzip libleveldb-dev python3.12-venv python3-pip python3-venv python3-dev

echo -e "${GREEN}Добавление Yarn и установка Node.js 22...${NC}"
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo gpg --dearmor -o /usr/share/keyrings/yarnkey.gpg
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo npm install -g yarn

echo -e "${GREEN}Node.js версия: $(node -v)${NC}"
echo -e "${GREEN}Yarn версия: $(yarn -v)${NC}"

echo -e "${GREEN}Клонируем репозиторий rl-swarm...${NC}"
rm -rf rl-swarm
git clone https://github.com/gensyn-ai/rl-swarm.git
cd rl-swarm

echo -e "${GREEN}Создание и активация виртуального окружения...${NC}"
python3 -m venv .venv
source .venv/bin/activate

echo -e "${GREEN}Запуск ноды через nohup...${NC}"
nohup bash -c "source .venv/bin/activate && ./run_rl_swarm.sh" > run.log 2>&1 &

echo -e "${GREEN}Установка и запуск завершены. Логи: ./rl-swarm/run.log${NC}"
