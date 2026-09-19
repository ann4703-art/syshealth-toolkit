#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${LAB2_REPO_DIR:-$HOME/syshealth-toolkit}"
cd "$REPO_DIR"

# The rubric requires a student-name hostname instead of the default localhost value.
if [[ "$(hostname)" == "localhost" || "$(hostname)" == "localhost.localdomain" ]]; then
    sudo hostnamectl set-hostname abdulaziz-alhaddad
fi

# Preserve the original Lab 1 script as the required safety backup.
if [[ ! -f syshealth.sh.bak ]]; then
    cp syshealth.sh syshealth.sh.bak
fi
chmod +x syshealth.sh

commit_if_changed() {
    local message="$1"
    git add syshealth.sh
    if ! git diff --cached --quiet; then
        git commit -m "$message"
    fi
}

# Commit 1: add configuration thresholds to the existing Lab 1 script.
python3 - <<'PY'
from pathlib import Path

path = Path("syshealth.sh")
text = path.read_text()
block = """# --- Thresholds (change these values to test alert behavior) ---
# Centralized thresholds allow alert sensitivity to change without rewriting the health-check logic.
CPU_THRESHOLD=75
MEM_THRESHOLD=85
DISK_THRESHOLD=85

"""
if "CPU_THRESHOLD=" not in text:
    lines = text.splitlines(keepends=True)
    insert_at = next((i + 1 for i, line in enumerate(lines) if line.startswith("# Date:")), 1)
    lines.insert(insert_at, block)
    path.write_text("".join(lines))
PY
commit_if_changed "Add threshold variables for CPU, memory, and disk"

# Commit 2: add the reusable color-output helper.
python3 - <<'PY'
from pathlib import Path

path = Path("syshealth.sh")
text = path.read_text()
function = r'''# print_status keeps all status formatting in one reusable location.
# local prevents function arguments from changing variables used elsewhere in the script.
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

'''
if "print_status()" not in text:
    marker = "DISK_THRESHOLD=85\n"
    text = text.replace(marker, marker + "\n" + function, 1)
    path.write_text(text)
PY
commit_if_changed "Implement color-coded status output"

# Commit 3: install the complete numeric parsing and conditional checks.
cat > syshealth.sh <<'SCRIPT'
#!/usr/bin/env bash
# Lab 2: Health Checks with Conditionals
# System Health and Log Analysis Toolkit for Rocky Linux 9
# Author: Abdulaziz Alhaddad
# Date: 2026-09-19

# --- Thresholds (change these values to test alert behavior) ---
# Centralized thresholds allow alert sensitivity to change without rewriting the health-check logic.
CPU_THRESHOLD=75
MEM_THRESHOLD=85
DISK_THRESHOLD=85

# print_status keeps all status formatting in one reusable location.
# local prevents function arguments from changing variables used elsewhere in the script.
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

# ${1:-} safely supplies an empty value when no output filename is provided.
OUTPUT_FILE="${1:-}"

# Command substitution captures each command's output for the final report.
# Double quotes preserve spaces in values and prevent unwanted word splitting.
CURRENT_DATE="$(date '+%Y-%m-%d %H:%M:%S')"
HOSTNAME="$(hostname)"
UPTIME="$(uptime -p)"
DISK_USAGE="$(df -hP / | awk 'NR == 2 {print $3 " used of " $2 " (" $5 ")"}')"
MEMORY_USAGE="$(free -h | awk '/^Mem:/ {print $3 " used of " $2}')"
PROCESS_COUNT="$(ps -e --no-headers | wc -l)"

# df -P gives predictable POSIX columns; awk removes % so Bash can compare an integer.
DISK_PCT="$(df -P / | awk 'NR == 2 {gsub(/%/, "", $5); print $5}')"

# awk calculates used/total memory and rounds it to a whole percentage.
MEM_PCT="$(free | awk '/^Mem:/ {printf "%.0f", ($3 / $2) * 100}')"

# The loop finds the field labelled idle instead of depending on one fragile column position.
# Removing nonnumeric characters leaves the idle value, which awk subtracts from 100.
CPU_PCT="$(LC_ALL=C top -bn1 | awk -F',' '/^%Cpu/ {
    for (i = 1; i <= NF; i++) {
        if ($i ~ / id/) {
            gsub(/[^0-9.]/, "", $i)
            printf "%.0f", 100 - $i
            exit
        }
    }
}')"

# A shared alert counter makes one or many failed checks produce exit code 1.
ALERT_COUNT=0
print_status "CHECK" "Running system health analysis..."

# =~ inside [[ ]] validates parsed values before arithmetic expansion uses them.
if [[ ! "$DISK_PCT" =~ ^[0-9]+$ ]]; then
    print_status "ALERT" "Unable to determine disk usage on /"
    ((ALERT_COUNT += 1))
elif (( DISK_PCT > DISK_THRESHOLD )); then
    print_status "ALERT" "Disk usage on / is ${DISK_PCT}% (threshold ${DISK_THRESHOLD}%)"
    ((ALERT_COUNT += 1))
else
    print_status "OK" "Disk usage on / is ${DISK_PCT}%"
fi

# Memory is checked only after confirming that awk returned an integer.
if [[ ! "$MEM_PCT" =~ ^[0-9]+$ ]]; then
    print_status "ALERT" "Unable to determine memory usage"
    ((ALERT_COUNT += 1))
elif (( MEM_PCT > MEM_THRESHOLD )); then
    print_status "ALERT" "Memory usage is ${MEM_PCT}% (threshold ${MEM_THRESHOLD}%)"
    ((ALERT_COUNT += 1))
else
    print_status "OK" "Memory usage is ${MEM_PCT}%"
fi

# CPU is checked only after confirming that top and awk returned an integer.
if [[ ! "$CPU_PCT" =~ ^[0-9]+$ ]]; then
    print_status "ALERT" "Unable to determine CPU usage"
    ((ALERT_COUNT += 1))
elif (( CPU_PCT > CPU_THRESHOLD )); then
    print_status "ALERT" "CPU usage is ${CPU_PCT}% (threshold ${CPU_THRESHOLD}%)"
    ((ALERT_COUNT += 1))
else
    print_status "OK" "CPU usage is ${CPU_PCT}%"
fi

# Any alert makes the script unhealthy; otherwise it remains healthy.
if (( ALERT_COUNT > 0 )); then
    HEALTH_STATUS=1
    HEALTH_TEXT="UNHEALTHY - see alerts above"
else
    HEALTH_STATUS=0
    HEALTH_TEXT="HEALTHY"
fi

# printf uses explicit formats so collected values cannot become format strings.
print_report() {
    printf "========================================\n"
    printf "System Health Report - %s\n" "$CURRENT_DATE"
    printf "Hostname          : %s\n" "$HOSTNAME"
    printf "Uptime            : %s\n" "$UPTIME"
    printf "Disk /            : %s\n" "$DISK_USAGE"
    printf "Memory used       : %s\n" "$MEMORY_USAGE"
    printf "Total processes   : %s\n" "$PROCESS_COUNT"
    printf "Health status     : %s\n" "$HEALTH_TEXT"
    printf "========================================\n"
}

# [[ -n ]] safely tests whether the optional output filename is nonempty.
if [[ -n "$OUTPUT_FILE" ]]; then
    print_report > "$OUTPUT_FILE"
    echo "Report written to $OUTPUT_FILE (alerts were printed to terminal)"
else
    print_report
fi

# Exit 0 means healthy; exit 1 allows cron or another script to detect an alert.
exit "$HEALTH_STATUS"
SCRIPT
chmod +x syshealth.sh
commit_if_changed "Add conditional CPU memory and disk checks"

# Commit 4: insert the required /, /home, and /var mount-point loop.
python3 - <<'PY'
from pathlib import Path

path = Path("syshealth.sh")
text = path.read_text()
loop = r'''# The for loop checks every required mount point using the same threshold.
# mountpoint -q avoids parsing directory text and 2>/dev/null hides expected lookup errors.
for mount in / /home /var; do
    if mountpoint -q "$mount" 2>/dev/null || [[ "$mount" == "/" ]]; then
        # df -P and awk provide a predictable percentage; quotes protect mount names.
        PCT="$(df -P "$mount" | awk 'NR == 2 {gsub(/%/, "", $5); print $5}')"

        if [[ ! "$PCT" =~ ^[0-9]+$ ]]; then
            print_status "ALERT" "Unable to determine disk usage on $mount"
            ((ALERT_COUNT += 1))
        elif (( PCT > DISK_THRESHOLD )); then
            print_status "ALERT" "Disk usage on $mount is ${PCT}% (threshold ${DISK_THRESHOLD}%)"
            ((ALERT_COUNT += 1))
        else
            print_status "OK" "Disk usage on $mount is ${PCT}%"
        fi
    else
        print_status "OK" "Mount point $mount does not exist or is not a mountpoint on this system"
    fi
done

'''
marker = "# Memory is checked only after confirming that awk returned an integer.\n"
if "for mount in / /home /var" not in text:
    text = text.replace(marker, loop + marker, 1)
    path.write_text(text)
PY
commit_if_changed "Add mount-point loop and health exit code"

# Validate syntax, generate the required report, and preserve its real exit status.
bash -n syshealth.sh
set +e
bash syshealth.sh monitor_with_alerts.txt
SCRIPT_EXIT=$?
set -e

# Export the exact Git history required for the Lab 2 submission.
git log --oneline --graph --decorate --all -20 > git_log_lab2.txt

printf '\nLab 2 setup complete. Script exit code: %s\n' "$SCRIPT_EXIT"
ls -l syshealth.sh syshealth.sh.bak monitor_with_alerts.txt git_log_lab2.txt
git log --oneline --decorate -8

# Push only committed source-code history; generated submission files remain available locally.
git push origin master

printf '\nFINAL STATUS\n'
git status --short
printf 'Use this exit code in the required screenshot: %s\n' "$SCRIPT_EXIT"
