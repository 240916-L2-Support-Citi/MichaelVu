#!/bin/bash

# Path to the log file to monitor
LOGFILE="/var/log/app.log"
PREVIOUSLOGS="/home/mv/project1/previous_logs.log"

# Database connection details
DB_USER="mv"
DB_NAME="project1"
DB_PASS="jjk123"

# Table in PostgreSQL to store log entries
TABLE="log_entries"

# Function to insert log entry into PostgreSQL
insert_log_entry() {
    local timestamp=$1
    local level=$2
    local message=$3

    # Escape single quotes by replacing each ' with '' (FATAL message causing problems)
    # s = substitute g = global/replaces all occurrences 
    local escaped_message=$(echo "$message" | sed "s/'/''/g")
    
    PGPASSWORD=$DB_PASS psql -U $DB_USER -d $DB_NAME -c \
    "INSERT INTO $TABLE (timestamp, level, message) VALUES ('$timestamp', '$level', '$escaped_message');"
}

# Monitor the log file for ERROR and FATAL entries
while read line; do
    # Extract log information (timestamp, level, message)

    # awk is command used for text processing, it used here to get columns 1 and 2 for the timestamp
    TIMESTAMP=$(echo $line | awk '{print $1" "$2}')

    # Get the 3rd column from the line, then tr -d deletes the brackets from the column
    LEVEL=$(echo $line | awk '{print $3}' | tr -d '[]')

    # cut splits the line based on the delimiter (-d)
    # then takes everything in the 2nd field (-f2-), which is the log message
    MESSAGE=$(echo $line | cut -d']' -f2-)
    
    # Check if the log level is ERROR or FATAL
    if [[ "$LEVEL" == "ERROR" || "$LEVEL" == "FATAL" ]]; then
        echo "Inserting $LEVEL log entry into database: $MESSAGE"
        # Insert the log entry into PostgreSQL
        insert_log_entry "$TIMESTAMP" "$LEVEL" "$MESSAGE"
    fi
 done < "$LOGFILE"

 cat $LOGFILE >> $PREVIOUSLOGS

# Clears the log file to prevent duplicate entries
> "$LOGFILE"