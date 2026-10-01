#!/usr/bin/env bash
set -euo pipefail

host="127.0.0.1"
port="4444"
session_file="/tmp/.sessao_4471"

if ! command -v nc >/dev/null 2>&1; then
    printf 'Erro: instale o netcat (comando nc) para executar a simulacao.\n' >&2
    exit 1
fi

if nc -z -w 1 "$host" "$port" >/dev/null 2>&1; then
    printf 'Erro: a porta %s ja esta em uso em %s.\n' "$port" "$host" >&2
    exit 1
fi

if [[ -e "$session_file" ]]; then
    printf 'Erro: o arquivo %s ja existe; ele nao sera sobrescrito.\n' "$session_file" >&2
    exit 1
fi

umask 077
printf 'Arquivo temporario da simulacao forense.\nCriado em UTC: %s\n' \
    "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" > "$session_file"

nc -l -k "$host" "$port" >/dev/null 2>&1 &
listener_pid=$!

ready=false
for attempt in {1..30}; do
    if command -v ss >/dev/null 2>&1; then
        if ss -ltn 2>/dev/null | grep -Fq "$host:$port"; then
            ready=true
            break
        fi
    elif nc -z -w 1 "$host" "$port" >/dev/null 2>&1; then
        ready=true
        break
    fi

    if ! kill -0 "$listener_pid" 2>/dev/null; then
        break
    fi
    sleep 0.1
done

if [[ "$ready" != true ]]; then
    kill "$listener_pid" 2>/dev/null || true
    rm -f "$session_file"
    printf 'Erro: nao foi possivel iniciar o listener em %s:%s.\n' "$host" "$port" >&2
    exit 1
fi

printf 'Simulacao ativa: listener PID %s em %s:%s.\n' "$listener_pid" "$host" "$port"
printf 'Arquivo temporario criado: %s\n' "$session_file"
printf "Para encerrar, use: pkill -f '[n]c -l -k 127.0.0.1 4444'\n"