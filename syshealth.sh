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

main() {
    parse_arguments "$@"
    run_health_checks
    generate_report
}

# The single call that starts everything
main
