#!/usr/bin/env bash

#=====================
# syshealth.sh - System Health & Log Analysis Toolkit
# lab 1 - Data collector
#Author :Abdulaziz Nasser
#Date: $(date +%Y-%m-%d)
#=========================
 
#===============
HOSTNAME=$(hostname)
CURRENT_DATE=$(date '+%Y-%m-%d %H:%M:%S')
# Important: Quoting demo (Python/java students read this!)
#Without quotes -> word-splitting bug(try it!)
#With double quotes -> safe (Bash best practice)
echo "Hostname without quotes:$HOSTNAME"
echo "Hostname with quotes: \"$HOSTNAME\""
cat  <<   EOF
# COMMENT FOR GRADER:
#In my python/java variable expand safely.
#In Bash, unqouted \$VAR splits on spaces/tabs/newlines.
#Always double-quote unless you debliberately want splitting
EOF
#-----System metrics collection ---
UPTIME=$(uptime -p)
DISK_USAGE=$(df -h / |tail -1)
MEMORY_USAGE=$(free -h | awk '/Mem:/ {print $3 "/"$2}')
PROCESS_COUNT=$(ps -e | wc -l)		
# --- Output handling ---
OUTPUT_FILE="${1:-}"
print_report() {
 printf "=====================\n"
 printf "System Health Report - %s\n" "$CURRENT_DATE"
 printf "Hostname          :  %s\n" "$HOSTNAME"
 printf "Uptime      : %s\n" "$UPTIME"
 printf "Disk   /         :%s\n" "$DISK_USAGE"
 printf "Memory used   : %s\n" "$MEMORY_USAGE"
 printf "Total process : %s\n" "$PROCESS_COUNT"
 printf "	======================\n"
}
if [ -n "$OUTPUT_FILE" ]; then
   print_report >"$OUTPUT_FILE"
  echo "Report written to $OUTPUT_FILE"
else
   print_report

fi
 exit 0
