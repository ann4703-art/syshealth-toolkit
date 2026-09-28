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

main() {
    parse_arguments "$@"
    run_health_checks
    generate_report
}

# The single call that starts everything
main
