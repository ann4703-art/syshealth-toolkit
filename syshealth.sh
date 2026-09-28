#!/usr/bin/env bash
# The shebang above uses Bash through env, exactly as required by the assignment.

# ===============================================
# syshealth.sh - System Health & Log Analysis Toolkit
# Lab 3 - Refactoring into Functions
# Author: Abdulaziz Alhaddad
# Date: 2026-09-28
# ===============================================

# These are global thresholds because several functions need to read them.
# CPU usage above 75 percent produces an alert.
CPU_THRESHOLD=75
# Memory usage above 85 percent produces an alert.
MEM_THRESHOLD=85
# Disk usage above 85 percent produces an alert.
DISK_THRESHOLD=85

# print_status receives a status in $1 and a message in $2.
# It keeps all OK, ALERT, and informational output consistent.
print_status() {
    # local prevents this variable from affecting variables outside the function.
    local status="$1"
    # The expansion is double-quoted to prevent unwanted word splitting.
    local message="$2"

    # [[ ]] safely compares the status text with OK.
    if [[ "$status" == "OK" ]]; then
        # \e[32m prints healthy results in green and \e[0m resets the color.
        echo -e "\e[32mOK: $message\e[0m"
    # This condition checks whether the status is ALERT.
    elif [[ "$status" == "ALERT" ]]; then
        # \e[31m prints alerts in red and \e[0m resets the color.
        echo -e "\e[31mALERT: $message\e[0m"
    else
        # CHECK and other informational statuses are printed normally.
        echo "$status: $message"
    fi
}

# check_disk_usage checks the mount point passed to the function through $1.
# It returns 0 for a healthy result and 1 when disk usage causes an alert.
check_disk_usage() {
    # Store the mount-point parameter in a local, double-quoted variable.
    local mount="$1"
    # Declare the calculated percentage and threshold as local variables.
    local pct threshold
    # Copy the global disk threshold into the function's local threshold.
    threshold="$DISK_THRESHOLD"

    # mountpoint checks whether the path is a mounted filesystem.
    # The root path is allowed even if mountpoint behaves differently on a system.
    if ! mountpoint -q "$mount" 2>/dev/null && [ "$mount" != "/" ]; then
        # A missing optional mount is reported clearly and is not treated as a failure.
        print_status "OK" "Mount point $mount does not exist on this system"
        # Return 0 because a missing optional mount does not create an alert.
        return 0
    fi

    # df gets disk usage, tail selects its data row, and awk removes the percent sign.
    pct=$(df "$mount" | tail -1 | awk '{gsub("%",""); print $5}')

    # (( )) performs a numeric comparison between usage and the threshold.
    if (( pct > threshold )); then
        # Print the disk alert with the mount, percentage, and threshold.
        print_status "ALERT" "Disk usage on $mount is ${pct}% (threshold ${threshold}%)"
        # Return 1 so the caller knows that this check produced an alert.
        return 1
    else
        # Print a green OK message when disk usage is within the threshold.
        print_status "OK" "Disk usage on $mount is ${pct}%"
        # Return 0 to show that the disk check is healthy.
        return 0
    fi
}

# check_memory_usage calculates and checks the percentage of memory being used.
# It returns 0 for healthy memory use and 1 when the threshold is exceeded.
check_memory_usage() {
    # Declare the calculated percentage and threshold as local variables.
    local pct threshold
    # Copy the global memory threshold into the local threshold.
    threshold="$MEM_THRESHOLD"
    # free supplies memory values and awk calculates used divided by total times 100.
    pct=$(free | awk '/Mem:/ {printf "%.0f", $3/$2*100}')

    # (( )) compares the numeric memory percentage with the threshold.
    if (( pct > threshold )); then
        # Print a red alert when memory usage is too high.
        print_status "ALERT" "Memory usage is ${pct}% (threshold ${threshold}%)"
        # Return 1 to report an unhealthy memory result.
        return 1
    else
        # Print a green OK message when memory usage is acceptable.
        print_status "OK" "Memory usage is ${pct}%"
        # Return 0 to report a healthy memory result.
        return 0
    fi
}

# check_cpu_usage calculates and checks the current CPU-use percentage.
# It returns 0 for healthy CPU use and 1 when the threshold is exceeded.
check_cpu_usage() {
    # Declare the calculated percentage and threshold as local variables.
    local pct threshold
    # Copy the global CPU threshold into the local threshold.
    threshold="$CPU_THRESHOLD"
    # top supplies CPU data, awk subtracts idle time from 100, and cut removes decimals.
    pct=$(top -bn1 | grep '^%Cpu' | awk '{print 100 - $8}' | cut -d. -f1)

    # (( )) compares the numeric CPU percentage with the threshold.
    if (( pct > threshold )); then
        # Print a red alert when CPU usage is too high.
        print_status "ALERT" "CPU usage is ${pct}% (threshold ${threshold}%)"
        # Return 1 to report an unhealthy CPU result.
        return 1
    else
        # Print a green OK message when CPU usage is acceptable.
        print_status "OK" "CPU usage is ${pct}%"
        # Return 0 to report a healthy CPU result.
        return 0
    fi
}

# run_health_checks calls all required checks and combines their return codes.
run_health_checks() {
    # Start with 0, which represents an overall healthy status.
    local overall_status=0
    # mount is local because it is used only by this function's loop.
    local mount

    # Display the message that health analysis is starting.
    print_status "CHECK" "Running system health analysis..."

    # Loop through the three mount points required by the assignment.
    for mount in / /home /var; do
        # ! makes this condition true when check_disk_usage returns 1.
        if ! check_disk_usage "$mount"; then
            # Preserve an unhealthy result if any disk check reports an alert.
            overall_status=1
        fi
    done

    # Run the memory function and detect its return code.
    if ! check_memory_usage; then
        # Set the overall result to unhealthy when memory produces an alert.
        overall_status=1
    fi

    # Run the CPU function and detect its return code.
    if ! check_cpu_usage; then
        # Set the overall result to unhealthy when CPU produces an alert.
        overall_status=1
    fi

    # Store the combined result globally for the report and final program exit.
    HEALTH_STATUS="$overall_status"
    # Return the same combined status to the function's caller.
    return "$overall_status"
}

# parse_arguments handles the optional report filename supplied by the user.
parse_arguments() {
    # ${1:-} uses $1 when provided or an empty value when no argument is given.
    OUTPUT_FILE="${1:-}"
}

# generate_report collects the human-readable Assignment 2 metrics and prints them.
generate_report() {
    # Every metric variable is local to satisfy the function-variable requirement.
    local CURRENT_DATE HOSTNAME UPTIME DISK_USAGE MEMORY_USAGE PROCESS_COUNT

    # Store the current date and time in the required format.
    CURRENT_DATE=$(date '+%Y-%m-%d %H:%M:%S')
    # Store the system hostname.
    HOSTNAME=$(hostname)
    # Store the system's human-readable uptime.
    UPTIME=$(uptime -p)
    # Store the human-readable root-filesystem disk row.
    DISK_USAGE=$(df -h / | tail -1)
    # Store used memory followed by total memory.
    MEMORY_USAGE=$(free -h | awk '/Mem:/ {print $3 "/" $2}')
    # Count all current processes.
    PROCESS_COUNT=$(ps -e | wc -l)

    # Print the opening report separator.
    printf "========================================\n"
    # Print each metric with a fixed format and a double-quoted value.
    printf "System Health Report - %s\n" "$CURRENT_DATE"
    printf "Hostname          : %s\n" "$HOSTNAME"
    printf "Uptime            : %s\n" "$UPTIME"
    printf "Disk /            : %s\n" "$DISK_USAGE"
    printf "Memory used       : %s\n" "$MEMORY_USAGE"
    printf "Total processes   : %s\n" "$PROCESS_COUNT"
    # Convert HEALTH_STATUS 0 or 1 into the required readable health message.
    printf "Health status     : %s\n" "$([ "${HEALTH_STATUS:-0}" -eq 0 ] && echo "HEALTHY" || echo "UNHEALTHY - see alerts above")"
    # Print the closing report separator.
    printf "========================================\n"
}

# main is the program's single orchestration function.
main() {
    # Pass every received argument to parse_arguments.
    parse_arguments "$@"

    # Run all health checks before generating the report.
    run_health_checks

    # Check whether the user supplied a nonempty output filename.
    if [ -n "$OUTPUT_FILE" ]; then
        # Redirect only the structured report into the requested file.
        generate_report > "$OUTPUT_FILE"
        # Confirm the name of the created report file.
        echo "Report written to $OUTPUT_FILE"
    else
        # Print the report on screen when no output filename was supplied.
        generate_report
    fi

    # Exit with 0 for healthy or 1 when any check generated an alert.
    exit "${HEALTH_STATUS:-0}"
}

# This is the only top-level action and must remain the final line.
# "$@" passes the script's optional arguments into the main function.
main "$@"
