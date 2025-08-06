````markdown
# Gensyn RL Swarm Node Installer

Automated Bash script for installing, launching, and managing the RL Swarm Gensyn node on Ubuntu.  
This script allows you to quickly deploy the node, manage dependencies, tunnels, swap files, and private keys through a convenient interactive menu — no manual configuration required.

---

## About

**Gensyn** is an AI infrastructure project backed by top investors such as a16z, Galaxy, and others.  
This script is designed to make node installation and management simple, even for beginners.

---

## System Requirements

- OS: Ubuntu 22.04+
- CPU: arm64 or x86
- RAM: **32 GB** recommended (tested with 6/16 GB using swap file setup)
- Root access (sudo)
- Disk space: **50 GB+** recommended
- Internet connection

---

## Quick Start

Copy and paste into your terminal:


wget -q -O GensynNode.sh https://raw.githubusercontent.com/ksydoruk1508/GensynNode/main/GensynNode.sh && sudo chmod +x GensynNode.sh && ./GensynNode.sh
````

---

## Features

* Installs all required dependencies (Python, Node.js, Yarn, localtunnel, etc.)
* Clones and updates the RL Swarm repository
* Runs the node inside a screen session for stable background operation
* Swap file management (create, enable/disable)
* Creates and runs an HTTPS tunnel using Cloudflared
* Backups and restores the private key (`swarm.pem`)
* User-friendly interactive menu

---

## Step-by-step Guide

1. **Download and run the script:**
   (see "Quick Start" above)

2. **Install dependencies**
   In the menu, select `1` and press Enter. Wait for the installation to complete.

3. **Clone the RL Swarm repository**
   In the menu, select `2` and press Enter.

4. **Start the node**
   In the menu, select `3` and press Enter.
   The node will run in a screen session named `gensyn`.

5. **Start HTTPS tunnel (Cloudflared)**
   In the menu, select `8` and press Enter.
   The tunnel will run in a separate screen session named `cftunnel`.

6. **Open two terminal windows:**

   * First window: `screen -r gensyn`
   * Second window: `screen -r cftunnel`

7. **When you see the message:**

   ```
   >> Failed to open http://localhost:3000. Please open it manually.
   >> Waiting for modal userData.json to be created ...
   ```

   * Switch to the cftunnel window and copy the link shown after:
     `Your quick Tunnel has been created! Visit it at: ...`
   * Open that link in your browser and log in using your email.

8. **After successful login, return to the gensyn screen**
   Wait for the prompt:

   ```
   >> Would you like to push models you train in the RL swarm to the Hugging Face Hub? [y/N]
   ```

   Simply press Enter.

9. **Next prompt – model selection:**
   Either press Enter to select the default or choose one from the list (from least to most demanding):

   * Gensyn/Qwen2.5-0.5B-Instruct
   * Qwen/Qwen3-0.6B
   * nvidia/AceInstruct-1.5B
   * dnotitia/Smoothie-Qwen3-1.7B
   * Gensyn/Qwen2.5-1.5B-Instruct

10. **If you see model downloads starting — congratulations, your node is running!**
    You can close the terminal or detach the sessions using `CTRL + A + D`.

---

## Additional Menu Functions

* Update RL Swarm to the latest version (`4`)
* Check current node version (`5`)
* Remove RL Swarm while keeping the private key (`6`)
* Restore private key from backup (`7`)
* Manage swap file (`9`)
* Exit script (`10`)

---

## FAQ

**Q:** I don’t have enough RAM, what should I do?
**A:** Use menu option `9` to create and activate a swap file.

**Q:** Where are private keys stored?
**A:** The private key `swarm.pem` is stored in `~/rl-swarm/`. A backup is automatically saved to `~/swarm.pem.backup` before deletion.

**Q:** How to restore the private key after reinstalling?
**A:** Use menu option `7`.

**Q:** Which operating systems are supported?
**A:** Ubuntu 22.04+ (x86, arm64). Other OS may have dependency issues.

---

## Support & Contacts

* Telegram Chat: [@nod3r\_team](https://t.me/nod3r_team)
* Telegram Channel: [@nod3r](https://t.me/nod3r)
* Bot: [@wiki\_nod3r\_bot](https://t.me/wiki_nod3r_bot)
* GitHub: [ksydoruk1508/GensynNode](https://github.com/ksydoruk1508/GensynNode)

---

**If you have questions or issues — feel free to reach out via Telegram or GitHub Issues!**
_________________________________________________________________________________________________________________________________________________

---

````markdown
# Gensyn RL Swarm Node Installer

Автоматизированный Bash-скрипт для установки, запуска и управления RL Swarm нодой Gensyn на Ubuntu.  
Позволяет быстро развернуть ноду, управлять зависимостями, туннелями, swap-файлом и приватными ключами через удобное меню — без ручной настройки.

---

## О проекте

**Gensyn** — инфраструктурный AI-проект, поддержанный инвесторами вроде a16z, Galaxy и др.  
Скрипт предназначен для максимально быстрой установки и простого управления вашей нодой Gensyn RL Swarm даже для новичков.

---

## Системные требования

- ОС: Ubuntu 22.04+  
- CPU: arm64 или x86  
- RAM: **32GB** рекомендуется (но работает и на 6/16GB при использовании swap, который можно настроить через скрипт)  
- Root-доступ (sudo)
- Свободное место на диске: **от 50 ГБ** (рекомендуется)
- Доступ в интернет

---

## Быстрый старт

Скопируйте и вставьте в терминал:


wget -q -O GensynNode.sh https://raw.githubusercontent.com/ksydoruk1508/GensynNode/main/GensynNode.sh && sudo chmod +x GensynNode.sh && ./GensynNode.sh
````

---

## Основные возможности

* Установка всех необходимых зависимостей (Python, Node.js, Yarn, localtunnel и др.)
* Клонирование и обновление репозитория RL Swarm
* Запуск ноды в отдельной screen-сессии для стабильной работы в фоне
* Управление swap-файлом (создание, активация/деактивация)
* Создание и запуск HTTPS-туннеля через Cloudflared (для взаимодействия с браузером)
* Бэкап и восстановление приватного ключа (`swarm.pem`)
* Удобное интерактивное меню

---

## Пошаговая инструкция

1. **Скачайте и запустите скрипт:**
   (см. "Быстрый старт" выше)

2. **Установите зависимости**
   В меню выберите `1` и нажмите Enter. Дождитесь окончания установки.

3. **Клонируйте репозиторий RL Swarm**
   В меню выберите `2` и нажмите Enter.

4. **Запустите ноду**
   В меню выберите `3` и нажмите Enter.
   Нода будет работать в screen-сессии `gensyn`.

5. **Запустите HTTPS-туннель (Cloudflared)**
   В меню выберите `8` и нажмите Enter.
   Туннель запустится в отдельной screen-сессии `cftunnel`.

6. **Откройте две вкладки терминала:**

   * В первой введите: `screen -r gensyn`
   * Во второй: `screen -r cftunnel`

7. **Когда увидите сообщение:**

   ```
   >> Failed to open http://localhost:3000. Please open it manually.
   >> Waiting for modal userData.json to be created ...
   ```

   * Перейдите в окно cftunnel, скопируйте ссылку после
     `Your quick Tunnel has been created! Visit it at: ...`
   * Откройте эту ссылку в браузере и залогиньтесь через почту.

8. **После успешной авторизации вернитесь к окну gensyn**

   * Дождитесь появления вопроса:

     ```
     >> Would you like to push models you train in the RL swarm to the Hugging Face Hub? [y/N]
     ```

     Просто нажмите Enter.

9. **Следующий вопрос — выбор модели:**
   Можно просто нажать Enter, либо ввести название из списка (от наименее требовательной к наиболее):

   * Gensyn/Qwen2.5-0.5B-Instruct
   * Qwen/Qwen3-0.6B
   * nvidia/AceInstruct-1.5B
   * dnotitia/Smoothie-Qwen3-1.7B
   * Gensyn/Qwen2.5-1.5B-Instruct

10. **Если видите загрузку моделей — поздравляем, нода работает!**
    Можно закрыть терминал или скрыть сессии комбинацией клавиш `CTRL + A + D`.

---

## Дополнительные функции меню

* Обновить RL Swarm до актуальной версии (`4`)
* Проверить текущую версию ноды (`5`)
* Удалить RL Swarm с сохранением приватника (`6`)
* Восстановить приватный ключ из бэкапа (`7`)
* Управлять swap-файлом (`9`)
* Выйти из скрипта (`10`)

---

## FAQ

**Q:** Мало оперативной памяти, что делать?
**A:** Используйте функцию меню №9 для создания и активации swap-файла.

**Q:** Где хранятся приватные ключи?
**A:** Приватник `swarm.pem` сохраняется в `~/rl-swarm/`. Перед удалением скрипт делает резервную копию в `~/swarm.pem.backup`.

**Q:** Как восстановить приватный ключ после переустановки?
**A:** Используйте пункт меню №7.

**Q:** На каких ОС гарантированно работает скрипт?
**A:** Ubuntu 22.04+ (x86, arm64). На других системах возможны проблемы с зависимостями.

---

## Поддержка и контакты

* Telegram-чат: [@nod3r\_team](https://t.me/nod3r_team)
* Telegram-канал: [@nod3r](https://t.me/nod3r)
* Бот: [@wiki\_nod3r\_bot](https://t.me/wiki_nod3r_bot)
* GitHub: [ksydoruk1508/GensynNode](https://github.com/ksydoruk1508/GensynNode)

---

**Если возникли вопросы или проблемы — пишите в чат или Issues на GitHub!**
