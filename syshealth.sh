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

main() {
    parse_arguments "$@"
    run_health_checks
    generate_report
}

# The single call that starts everything
main
