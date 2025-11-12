#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C
: "${HOME:=/root}"

# ---------- Пути/параметры ----------
REPO_DIR="${REPO_DIR:-${HOME}/rl-swarm}"
VENV_DIR="${VENV_DIR:-${REPO_DIR}/.venv}"
SCREEN_NAME="${SCREEN_NAME:-gensyn}"

# ---------- Цвета (как на скрине) ----------
clrGreen=$'\033[0;32m'   # версии, OK/Running
clrCyan=$'\033[0;36m'    # ключи/метки (BASE_DIR и т.п.)
clrBlue=$'\033[0;34m'    # значения путей/URL/числа
clrRed=$'\033[0;31m'     # ошибки/-
clrYellow=$'\033[1;33m'  # подчёркнутые детали (нечасто)
clrMag=$'\033[1;35m'     # заголовки разделов
clrDim=$'\033[2m'        # разделители/тонкое
clrBold=$'\033[1m'
clrReset=$'\033[0m'

hr(){ echo -e "${clrDim}────────────────────────────────────────────────────────────${clrReset}"; }

# ---------- Утилиты ----------
hum(){ awk -v b="${1:-0}" '
  function H(x){u[0]="B";u[1]="KB";u[2]="MB";u[3]="GB";u[4]="TB";i=0;while(x>=1024&&i<4){x/=1024;i++}printf "%.2f%s",x,u[i]}
  BEGIN{H(b)}
'; }
b_of(){ [[ -e "$1" ]] && du -sb "$1" 2>/dev/null | awk '{print $1}' || echo 0; }
whichp(){ command -v "$1" 2>/dev/null || true; }
fsize(){ local p; p="$(whichp "$1")"; [[ -n "$p" && -f "$p" ]] && stat -c '%s' "$p" 2>/dev/null || echo 0; }
fmt_seconds(){ local s="${1:-0}"; printf "%dd %02d:%02d:%02d" "$((s/86400))" "$((s%86400/3600))" "$((s%3600/60))" "$((s%60))"; }

get_screen_pid(){ screen -list 2>/dev/null | awk -v n=".${SCREEN_NAME}" '$0~n{ s=$1; sub(/\..*/,"",s); print s; exit }'; }

collect_descendants_bfs(){
  local root="${1-}"; [[ -n "$root" ]] || return
  local q=("$root") seen=()
  while ((${#q[@]})); do
    local p="${q[0]}"; q=("${q[@]:1}")
    [[ " ${seen[*]} " == *" $p "* ]] || {
      seen+=("$p")
      mapfile -t kids < <(ps -o pid= --ppid "$p" 2>/dev/null | awk 'NF')
      ((${#kids[@]})) && q+=("${kids[@]}")
    }
  done
  printf "%s\n" "${seen[@]}" | sort -u
}

# ---------- Метрики процесса внутри screen ----------
RUNNING=false; UPTIME_HUMAN="-"; CPU_TOTAL="0.00"; RAM_TOTAL=0; MEM_PCT="0.00"
calc_metrics(){
  local spid; spid="$(get_screen_pid || true)"
  [[ -n "${spid:-}" ]] || return
  mapfile -t ALL < <(collect_descendants_bfs "$spid")
  ((${#ALL[@]})) || return

  local CPU_SUM=0.00 RSS_BYTES=0 ET_MAX=0 keep_any=false
  while read -r pid comm et rss_k pcpu; do
    [[ -z "$pid" ]] && continue
    [[ "$comm" =~ ^(python|python3|wandb-core|gpu_stats)$ ]] || continue
    keep_any=true
    (( RSS_BYTES += rss_k * 1024 ))
    (( et > ET_MAX )) && ET_MAX="$et"
    CPU_SUM=$(awk -v a="$CPU_SUM" -v b="$pcpu" 'BEGIN{printf "%.2f", a+b}')
  done < <(ps -o pid=,comm=,etimes=,rss=,pcpu= -p "$(printf "%s," "${ALL[@]}" | sed 's/,$//')" 2>/dev/null)

  $keep_any || return
  RUNNING=true
  CPU_TOTAL="$CPU_SUM"
  RAM_TOTAL="$RSS_BYTES"
  UPTIME_HUMAN="$(fmt_seconds "$ET_MAX")"
  MEM_PCT=$(awk -v r="$RSS_BYTES" -v t="$(awk '/MemTotal/{print $2*1024}' /proc/meminfo)" 'BEGIN{ if(t>0) printf "%.2f",(r*100)/t; else print "0.00"}')
}

# ---------- Порты ----------
port_state(){
  local p="$1"
  if ss -lnt 2>/dev/null | awk '{print $4}' | awk -F':' '{print $NF}' | grep -qx "$p"; then
    echo -e "${clrGreen}listening${clrReset}"
  else
    echo -e "${clrRed}-${clrReset}"
  fi
}

# ---------- Блоки ----------
line_kv(){ # key, value
  echo -e "  ${clrCyan}${1}${clrReset}:  ${clrBlue}${2}${clrReset}"
}

print_tool(){
  local title="$1" ver="$2" path="$3" size_h="$4"
  echo -e "${clrBold}${title}${clrReset}:     ${clrGreen}${ver}${clrReset}"
  echo -e "  ${clrCyan}path${clrReset}:            ${clrBlue}${path:-"-"}${clrReset}"
  echo -e "  ${clrCyan}size${clrReset}:            ${clrBlue}${size_h}${clrReset}"
  echo
}

print_dashboard(){
  echo -e "${clrMag}${clrBold}Gensyn — Usage Dashboard${clrReset}"
  hr
  line_kv "REPO" "${REPO_DIR}"
  line_kv "SESSION" "${SCREEN_NAME}"
  echo -e "${clrCyan}swarm.pem${clrReset}:  $([[ -f "$REPO_DIR/swarm.pem" ]] && echo "${clrGreen}present${clrReset}" || echo "${clrRed}absent${clrReset}")"
  hr

  echo -e "${clrBold}Диск (репо)${clrReset}:"
  echo -e "  ${clrCyan}REPO${clrReset}:  ${clrBlue}$(hum "$(b_of "$REPO_DIR")")${clrReset}  (${clrBlue}$REPO_DIR${clrReset})"
  echo -e "  ${clrCyan}VENV${clrReset}:  ${clrBlue}$(hum "$(b_of "$VENV_DIR")")${clrReset}  (${clrBlue}$VENV_DIR${clrReset})"
  hr

  echo -e "${clrBold}Статус${clrReset}:  $([[ "${RUNNING:-false}" == true ]] && echo "${clrGreen}running${clrReset}  (running=true)" || echo "${clrRed}stopped${clrReset}  (running=false)")"
  echo -e "${clrBold}Аптайм${clrReset}:  ${clrBlue}$([[ "${RUNNING:-false}" == true ]] && echo "$UPTIME_HUMAN" || echo "-")${clrReset}"
  echo -e "${clrBold}CPU${clrReset}:    ${clrBlue}$([[ "${RUNNING:-false}" == true ]] && echo "${CPU_TOTAL}%" || echo "0%")${clrReset}  ${clrDim}(сумма по процессам ноды)${clrReset}"
  echo -e "${clrBold}RAM${clrReset}:    ${clrBlue}$([[ "${RUNNING:-false}" == true ]] && echo "$(hum "$RAM_TOTAL")" || echo "0B")${clrReset}  ${clrDim}($([[ "${RUNNING:-false}" == true ]] && echo "${MEM_PCT}%" || echo "0%"))${clrReset}"
  echo -e "${clrBold}Порты${clrReset}:"
  echo -e "  ${clrCyan}3000/tcp${clrReset} -> $(port_state 3000)"
  echo -e "  ${clrCyan}8080/tcp${clrReset} -> $(port_state 8080)"
  hr

  # Инструменты (версия зелёная, путь/размер синие)
  local py_ver node_ver yarn_ver cfd_ver
  py_ver="$(python3 -V 2>/dev/null || echo "-")"
  node_ver="$(node -v 2>/dev/null || echo "-")"
  yarn_ver="$(yarn -v 2>/dev/null || echo "-")"
  cfd_ver="$(cloudflared --version 2>/dev/null | head -1 || echo "-")"

  echo -e "${clrBold}Toolchain${clrReset}"
  hr
  print_tool "python (venv)" "${py_ver}" "${VENV_DIR}" "$(hum "$(b_of "$VENV_DIR")")"
  print_tool "node"           "${node_ver}" "$(whichp node)"          "$(hum "$(fsize node)")"
  print_tool "yarn (corepack)" "${yarn_ver}" "$(whichp yarn)"         "$(hum "$(fsize yarn)")"
  print_tool "cloudflared"    "${cfd_ver}"  "$(whichp cloudflared)"   "$(hum "$(fsize cloudflared)")"
  print_tool "screen"         "$(screen --version | head -1)" "$(whichp screen)" "$(hum "$(fsize screen)")"
  print_tool "git"            "$(git --version)" "$(whichp git)"       "$(hum "$(fsize git)")"

  hr
  echo -e "${clrMag}${clrBold}ИТОГО по Gensyn${clrReset}"
  hr
  local repo_b venv_b tool_b total_b
  repo_b="$(b_of "$REPO_DIR")"
  venv_b="$(b_of "$VENV_DIR")"
  tool_b=$(( $(fsize node) + $(fsize yarn) + $(fsize cloudflared) + $(fsize screen) + $(fsize git) ))
  total_b=$(( repo_b + venv_b + tool_b ))

  echo -e "${clrCyan}REPO${clrReset}:        ${clrBlue}$(hum "$repo_b")${clrReset}"
  echo -e "${clrCyan}VENV${clrReset}:        ${clrBlue}$(hum "$venv_b")${clrReset}"
  echo -e "${clrCyan}Toolchain${clrReset}:   ${clrBlue}$(hum "$tool_b")${clrReset}"
  hr
  echo -e "${clrBold}Общий размер:${clrReset}  ${clrBlue}$(hum "$total_b")${clrReset}"
  hr
}

# ---------- Запуск ----------
calc_metrics || true
print_dashboard
