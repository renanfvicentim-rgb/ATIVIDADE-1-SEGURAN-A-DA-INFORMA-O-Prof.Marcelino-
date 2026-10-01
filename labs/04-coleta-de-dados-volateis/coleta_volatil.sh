#!/usr/bin/env bash
set -euo pipefail
umask 077

lab_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
output_dir="$lab_dir/saida/coleta_$(date -u '+%Y%m%dT%H%M%SZ')_$$"
start_utc="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
start_local="$(date '+%Y-%m-%dT%H:%M:%S%:z %Z')"

if ! command -v sha256sum >/dev/null 2>&1; then
    printf 'Erro: sha256sum e necessario para verificar a integridade.\n' >&2
    exit 1
fi

mkdir -p "$output_dir"

run_or_note() {
    local command_name="$1"
    shift

    if command -v "$command_name" >/dev/null 2>&1; then
        "$@" || {
            local command_status=$?
            printf '[aviso] %s terminou com codigo %s.\n' "$command_name" "$command_status"
        }
    else
        printf '[indisponivel] Comando nao encontrado: %s\n' "$command_name"
    fi
}

capture() {
    local output_name="$1"
    shift
    local command_status=0

    {
        printf 'Horario da coleta (UTC): %s\n\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
        "$@" 2>&1 || {
            command_status=$?
            printf '\n[aviso] Coleta terminou com codigo %s.\n' "$command_status"
        }
    } > "$output_dir/$output_name"
}

clock_info() {
    date '+Horario local: %Y-%m-%dT%H:%M:%S%:z %Z'
    date -u '+Horario UTC: %Y-%m-%dT%H:%M:%SZ'
}

network_info() {
    run_or_note ip ip -brief address
    printf '\nRotas:\n'
    run_or_note ip ip route show
    printf '\nVizinhos ARP/ND:\n'
    run_or_note ip ip neigh show
}

process_info() {
    run_or_note ps ps -eo pid,ppid,user,lstart,stat,cmd --sort=start_time
}

connection_info() {
    run_or_note ss ss -tunap
}

memory_info() {
    if [[ -r /proc/meminfo ]]; then
        cat /proc/meminfo
    else
        printf '[indisponivel] /proc/meminfo nao pode ser lido.\n'
    fi
    printf '\nResumo de memoria:\n'
    run_or_note free free -h
}

kernel_info() {
    uname -a
    printf '\nModulos do kernel:\n'
    run_or_note lsmod lsmod
}

mount_info() {
    run_or_note findmnt findmnt -rn -o TARGET,SOURCE,FSTYPE,OPTIONS
}

disk_info() {
    run_or_note df df -hT
}

temporary_files_info() {
    ls -la /tmp
    printf '\nArquivo de sessao do exercicio:\n'
    if [[ -f /tmp/.sessao_4471 ]]; then
        run_or_note stat stat /tmp/.sessao_4471
        printf '\nConteudo:\n'
        cat /tmp/.sessao_4471
    else
        printf 'O arquivo /tmp/.sessao_4471 nao foi encontrado.\n'
    fi
}

capture '01_horarios.txt' clock_info
capture '02_rede.txt' network_info
capture '03_processos.txt' process_info
capture '04_conexoes.txt' connection_info
capture '05_kernel.txt' kernel_info
capture '06_memoria.txt' memory_info
capture '07_tmp.txt' temporary_files_info
capture '08_montagens.txt' mount_info
capture '09_disco.txt' disk_info

end_utc="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
end_local="$(date '+%Y-%m-%dT%H:%M:%S%:z %Z')"
{
    printf 'Inicio UTC: %s\n' "$start_utc"
    printf 'Inicio local: %s\n' "$start_local"
    printf 'Fim UTC: %s\n' "$end_utc"
    printf 'Fim local: %s\n' "$end_local"
    printf 'Host: %s\n' "$(hostname 2>/dev/null || printf 'indisponivel')"
    printf 'Diretorio da coleta: %s\n' "$output_dir"
    printf 'Hashes SHA-256: registrados em SHA256SUMS.\n'
} > "$output_dir/00_log_coleta.txt"

(
    cd "$output_dir"
    sha256sum ./*.txt > SHA256SUMS
)

printf 'Coleta concluida: %s\n' "$output_dir"
printf 'Verifique a integridade com: cd "%s" && sha256sum -c SHA256SUMS\n' "$output_dir"