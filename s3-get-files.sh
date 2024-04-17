#!/bin/bash

# Log file path
log_file="/root/SCRIPTS/logfile.txt"

# Function to log messages with timestamp
log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") $1" >> "$log_file"
}

# Create a unique processing directory name with timestamp
processing_dir="processing_$(date +"%Y-%m-%d_%H-%M-%S")"
s3cmd mb "s3://infinity-91872/$processing_dir"
log "Created processing directory: $processing_dir"

# List and filter files, excluding those in processing directories
files=$(s3cmd ls s3://infinity-91872 | grep -v ' DIR ' | awk '{print $4}' | grep -v '^$')

for file in $files; do
    if [[ $(basename "$file") == processing_* ]]; then
        log "Skipping already processing file: $file"
        continue
    fi

    dest="s3://infinity-91872/$processing_dir/$(basename "$file")"
    s3cmd mv "$file" "$dest"
    log "Moved $file to $dest"
done

# Define the source and target directories
src_dir="/root/SCRIPTS/tmp/"
target_dir="/root/IMPORTS/"

# Ensure directories exist
mkdir -p "$src_dir"
mkdir -p "$target_dir"

# Download files from the processing directory to local storage
s3cmd sync "s3://infinity-91872/$processing_dir/" "$src_dir"
log "Files synced to local storage for processing."

# Process each file
files=($(ls "$src_dir"))
for file in "${files[@]}"; do
    if [ -f "$src_dir$file" ]; then
        log "Starting import for file $file"
        
        # If processing is successful, move the file to the target directory.
        mv "$src_dir$file" "$target_dir"
        log "Moved $file to $target_dir"

        # Run the AMS import command. Replace or add actual commands as needed.
        php /var/www/ams/bin/console mautic:import:directory "$target_dir$file" >> "$log_file" 2>&1
        php /var/www/ams/bin/console mautic:import "$target_dir$file" >> "$log_file" 2>&1
        log "Import finished for file $file"

        # After successful processing, delete the file from the S3 processing directory
        s3cmd del "s3://infinity-91872/$processing_dir/$file"
        if [ $? -eq 0 ]; then
            log "Successfully deleted $file from S3 processing directory."
        else
            log "Failed to delete $file from S3 processing directory."
        fi
    fi
done

log "Script execution completed."
