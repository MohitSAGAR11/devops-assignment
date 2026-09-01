#!/bin/bash
# System Information Script
# Prints date, hostname, username, disk usage and running processes,
# then saves the process list into a file the user names.

# ---------- variables ----------
CURRENT_DATE=$(date)
HOST_NAME=$(hostname)
USER_NAME=$(whoami)
DISK_USAGE=$(df -h)

# ---------- 1. system information ----------
echo "=============================="
echo "     SYSTEM INFORMATION"
echo "=============================="
echo "Date      : $CURRENT_DATE"
echo "Hostname  : $HOST_NAME"
echo "Username  : $USER_NAME"
echo

echo "----- DISK USAGE (df -h) -----"
echo "$DISK_USAGE"
echo

echo "----- RUNNING PROCESSES (ps aux | head) -----"
ps aux | head -10
echo

# ---------- 2. take input from the user ----------
read -p "Enter a directory name to create : " DIR_NAME
read -p "Enter a file name to create      : " FILE_NAME

# fall back to defaults if the user just pressed Enter
DIR_NAME=${DIR_NAME:-sysinfo_dir}
FILE_NAME=${FILE_NAME:-processes.txt}

# ---------- 3. create directory and file ----------
mkdir -p "$DIR_NAME"
echo "Directory created : $DIR_NAME"

touch "$DIR_NAME/$FILE_NAME"
echo "File created      : $DIR_NAME/$FILE_NAME"
echo

# ---------- 4. store the running processes in the file ----------
ps aux > "$DIR_NAME/$FILE_NAME"
echo "Running processes saved to $DIR_NAME/$FILE_NAME"
echo "Lines written     : $(wc -l < "$DIR_NAME/$FILE_NAME")"
echo

echo "----- first 5 lines of $DIR_NAME/$FILE_NAME -----"
head -5 "$DIR_NAME/$FILE_NAME"
echo
echo "Done."
