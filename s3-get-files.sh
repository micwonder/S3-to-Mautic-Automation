#!/bin/bash

# Log file path
log_file="/root/SCRIPTS/logfile.txt"

# Function to log messages with timestamp
log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") $1" >> "$log_file"
}

# Get the files in the directory
log "Listing files in the S3 directory"
files=$(s3cmd ls s3://infinity-91872 | cut -d/ -f4)
s3cmd ls s3://infinity-91872 -r | cut -d/ -f4
log "Getting $files from S3"

s3cmd get "s3://infinity-91872/$files" "/root/SCRIPTS/tmp/"

# Define the source and target directories
src_dir="/root/SCRIPTS/tmp/"
target_dir="/root/IMPORTS/"

# Move the file to import directory
log "Moving $files to import directory"
cp "$src_dir$files" "$target_dir"

# Run the import
log "Starting import process"

# Get a list of all files in the source directory
log "Listing files in source directory"
files=($(ls "$src_dir"))

# Loop through each file
for file in "${files[@]}"; do
    log "Starting import for file $file"
    # Copy the file to the target directory
    mv "$src_dir$file" "$target_dir$file"
    # Run the AMS import command
    php /var/www/ams/bin/console mautic:import:directory >> "$log_file" 2>&1
    php /var/www/ams/bin/console mautic:import >> "$log_file" 2>&1
    log "Import finished for file $file"
done

log "Script execution completed"

