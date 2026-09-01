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
cat << EOF
# COMMENT FOR GRADER:
#In my python/java variable expand safely.
#In Bash, unqouted \$VAR splits on spaces/tabs/newlines.
#Always double-quote unless you debliberately want splitting EOF
#-----System metrics collection ---
UPTIME=$(uptime -p)
DISK_USAGE=$(df -h |tail -1)
MEMORY_USAGE=$(free -h | awk '/Mem:/ {print $3 "/"$2}')
PROCESS_COUNT=$(PS -e | wc -1)		
