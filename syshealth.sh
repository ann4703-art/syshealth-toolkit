#!/usr/bin/env bash

# ===============================================
# Lab 1: Bash Basics - Building the Data Collector
# Project: System Health & Log Analysis Toolkit
# Author: Abdulaziz Nasser
# Date: $(date +%Y-%m-%d)
# ===============================================

# This script collects basic information about the health of a Linux system.
# The shebang tells Linux to find Bash through env and use it to run the script.
# This form is portable because Bash may be stored in different locations.

# --- Variables and quoting demonstration ---

# Command substitution uses $(command) to run a command and save its result.
# Here, hostname finds the computer's name and stores it in HOSTNAME.
# Quotes are unnecessary during this assignment because Bash does not perform
# word splitting on values assigned directly to variables.
HOSTNAME=$(hostname)

# The date command returns the current date and time.
# The format is inside single quotes so it is passed as one argument to date.
CURRENT_DATE=$(date '+%Y-%m-%d %H:%M:%S')

# These lines demonstrate how a variable can appear in output.
# Double quotes protect the value and keep it together as one argument.
echo "Hostname without quotes: $HOSTNAME"
echo "Hostname with quotes: \"$HOSTNAME\""

# This message explains why quoting variables is important in Bash.
cat << EOF
QUOTING EXPLANATION:
If a variable is expanded without quotes, Bash may divide its value at spaces,
tabs, or new lines. It may also interpret wildcard characters in the value.
Writing "\$HOSTNAME" protects the value and treats it as one complete argument.
For this reason, I normally use double quotes when expanding Bash variables.
EOF

# --- System metrics collection ---

# uptime -p displays how long the system has been running in readable wording.
UPTIME=$(uptime -p)

# df -h / displays disk usage for the root filesystem in readable units.
# The pipe sends the result to tail, and tail -1 selects the final data line.
DISK_USAGE=$(df -h / | tail -1)

# free -h displays memory information in readable units.
# The pipe passes it to awk, which finds the Mem line and prints
# the used memory followed by the total memory.
MEMORY_USAGE=$(free -h | awk '/Mem:/ {print $3 "/" $2}')

# ps -e lists all running processes.
# The pipe sends the list to wc -l, which counts the number of lines.
PROCESS_COUNT=$(ps -e | wc -l)

# --- Output handling ---

# $1 represents the first argument entered after the script name.
# ${1:-} uses the first argument when it exists or an empty value otherwise.
# This allows the script to run safely even when no filename is supplied.
OUTPUT_FILE="${1:-}"

# This function contains the report format.
# Quoting each variable prevents unwanted word splitting.
print_report() {
    printf "========================================\n"
    printf "System Health Report - %s\n" "$CURRENT_DATE"
    printf "Hostname        : %s\n" "$HOSTNAME"
    printf "Uptime          : %s\n" "$UPTIME"
    printf "Disk /          : %s\n" "$DISK_USAGE"
    printf "Memory used     : %s\n" "$MEMORY_USAGE"
    printf "Total processes : %s\n" "$PROCESS_COUNT"
    printf "========================================\n"
}

# -n is true when OUTPUT_FILE is not empty.
# If a filename was supplied, > redirects the report into that file.
# Otherwise, the report is printed on the terminal screen.
if [ -n "$OUTPUT_FILE" ]; then
    print_report > "$OUTPUT_FILE"
    echo "Report written to $OUTPUT_FILE"
else
    print_report
fi

# Exit status 0 means the script finished successfully.
exit 0
