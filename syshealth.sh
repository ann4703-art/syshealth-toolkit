#!/usr/bin/env bash
# ===============================================
# syshealth.sh - System Health & Log Analysis Toolkit
# Lab 3 - Refactoring into Functions
# Author: Abdulaziz Alhaddad
# Date: 2026-09-28
# ===============================================

# --- Thresholds (change these values to test alert behavior) ---
# Centralized thresholds allow alert sensitivity to change without rewriting the health-check logic.
CPU_THRESHOLD=75
MEM_THRESHOLD=85
DISK_THRESHOLD=85

# --- Function definitions will go here ---
print_status() {
    local status="$1"
    local message="$2"

    # [[ ]] safely compares strings without accidental word splitting or pathname expansion.
    if [[ "$status" == "OK" ]]; then
        echo -e "\e[32mOK: $message\e[0m"
    elif [[ "$status" == "ALERT" ]]; then
        echo -e "\e[31mALERT: $message\e[0m"
    else
        echo "$status: $message"
    fi
}

check_disk_usage() {
    local mount="$1"
    local pct threshold
    threshold="$DISK_THRESHOLD"

    if ! mountpoint -q "$mount" 2>/dev/null && [ "$mount" != "/" ]; then
        print_status "OK" "Mount point $mount does not exist on this system"
        return 0
    fi

    pct=$(df "$mount" | tail -1 | awk '{gsub("%",""); print $5}')

    if (( pct > threshold )); then
        print_status "ALERT" "Disk usage on $mount is ${pct}% (threshold ${threshold}%)"
        return 1
    else
        print_status "OK" "Disk usage on $mount is ${pct}%"
        return 0
    fi
}

check_memory_usage() {
    local pct threshold
    threshold="$MEM_THRESHOLD"
    pct=$(free | awk '/Mem:/ {printf "%.0f", $3/$2*100}')

    if (( pct > threshold )); then
        print_status "ALERT" "Memory usage is ${pct}% (threshold ${threshold}%)"
        return 1
    else
        print_status "OK" "Memory usage is ${pct}%"
        return 0
    fi
}

check_cpu_usage() {
    local pct threshold
    threshold="$CPU_THRESHOLD"
    pct=$(top -bn1 | grep '^%Cpu' | awk '{print 100 - $8}' | cut -d. -f1)

    if (( pct > threshold )); then
        print_status "ALERT" "CPU usage is ${pct}% (threshold ${threshold}%)"
        return 1
    else
        print_status "OK" "CPU usage is ${pct}%"
        return 0
    fi
}

run_health_checks() {
    local overall_status=0
    local mount

    print_status "CHECK" "Running system health analysis..."

    for mount in / /home /var; do
        if ! check_disk_usage "$mount"; then
            overall_status=1
        fi
    done

    if ! check_memory_usage; then
        overall_status=1
    fi

    if ! check_cpu_usage; then
        overall_status=1
    fi

    HEALTH_STATUS="$overall_status"
    return "$overall_status"
}

parse_arguments() {
    OUTPUT_FILE="${1:-}"
}

generate_report() {
    local CURRENT_DATE HOSTNAME UPTIME DISK_USAGE MEMORY_USAGE PROCESS_COUNT

    CURRENT_DATE=$(date '+%Y-%m-%d %H:%M:%S')
    HOSTNAME=$(hostname)
    UPTIME=$(uptime -p)
    DISK_USAGE=$(df -h / | tail -1)
    MEMORY_USAGE=$(free -h | awk '/Mem:/ {print $3 "/" $2}')
    PROCESS_COUNT=$(ps -e | wc -l)

    printf "========================================\n"
    printf "System Health Report - %s\n" "$CURRENT_DATE"
    printf "Hostname          : %s\n" "$HOSTNAME"
    printf "Uptime            : %s\n" "$UPTIME"
    printf "Disk /            : %s\n" "$DISK_USAGE"
    printf "Memory used       : %s\n" "$MEMORY_USAGE"
    printf "Total processes   : %s\n" "$PROCESS_COUNT"
    printf "Health status     : %s\n" "$([ "${HEALTH_STATUS:-0}" -eq 0 ] && echo "HEALTHY" || echo "UNHEALTHY - see alerts above")"
    printf "========================================\n"
}

main() {
    parse_arguments "$@"

    run_health_checks

    if [ -n "$OUTPUT_FILE" ]; then
        generate_report > "$OUTPUT_FILE"
        echo "Report written to $OUTPUT_FILE"
    else
        generate_report
    fi

    exit "${HEALTH_STATUS:-0}"
}

main "$@"
