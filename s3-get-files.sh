#!/bin/bash

# Set the endpoint URL for AWS CLI operations to handle Digital Ocean space.
export AWS_ENDPOINT_URL=https://nyc3.digitaloceanspaces.com

# Log file path
log_file="/root/SCRIPTS/temp_logfile.txt"

# Function to log messages with timestamp
log() {
        echo "$(date +"%Y-%m-%d %H:%M:%S") $1" >> "$log_file"
}


log "---------------------------------------------"

# Setup the fixed-length processing directory name
# Create a unique processing directory name with timestamp
static_prefix="processing_"
base_processing_dir="$static_prefix$(date +"%Y-%m-%d_%H-%M-%S")"
required_length=31
padding_needed=$((required_length - ${#base_processing_dir}))
padding=$(printf '%*s' "$padding_needed" '' | tr ' ' '_')
processing_dir="${base_processing_dir}${padding}__"

# Function to check if a file is a processing file
is_processing_file() {
        local filename=$1
        local prefix_static="${filename:0:${#static_prefix}}"
        local prefix_full="${filename:0:$required_length}"
        local underscores="${filename:$required_length:2}"

        # echo "Debug: Comparing '$prefix_static' with '$static_prefix' and checking length of '$prefix_full'"
        # echo "Debug: UnderScores $underscores"

        # Check if the static part matches and if the total length of the prefix is as required.
        if [[ "$prefix_static" == "$static_prefix" && "${#prefix_full}" -eq $required_length && "$underscores" == "__" ]]; then
                echo "Skipping ... Already processed"
                return 0        # True, it is a processing file
        else
                echo "Processing ..."
                return 1        # False
        fi
}

# log "Attempt to create processing directory: $processing_dir"

# # Attempt to create a directory in the S3 bucket
# s3cmd mb "s3://infinity-91872/$processing_dir" --verbose 2>&1 | tee -a "$log_file"
# if [ "${PIPESTATUS[0]}" != "0" ]; then
#       log "Failed to create directory."
#       exit 1
# else
#       log "Successfully created directory: $processing_dir"
# fi

log "Processing directory: $processing_dir"

OLD_IFS="$IFS"

IFS=$'\n'

# List and filter files, excluding those in processing directories
# files=$(s3cmd ls s3://infinity-91872 | grep -v ' DIR ' | awk '{print $4}' | grep -v '^$')
# files=$(s3cmd ls s3://infinity-91872 | awk '{print $4}' | xargs -n 1 basename)
files=($(s3cmd ls s3://infinity-91872 --recursive | cut -d/ -f4))
# files=($(s3cmd ls s3://infinity-91872 --recursive | awk '{print substr($0, index($0,$3))}' | grep -v '^$'))

# files=($(s3cmd ls s3://infinity-91872 --recursive | rev | cut -d/ -f1 | rev))

IFS="$OLD_IFS"

# Array to hold paths that can be processed later
declare -a processible_paths

for file in "${files[@]}"; do
        echo "Checking file"
        processible_paths+=("$file")
        if is_processing_file "$file"; then
                log "Skipping already in processing file: $file"
                continue
        fi

        # Construct the full file path and destination path
        file_path="s3://infinity-91872/$file"
        dest_path="s3://infinity-91872/$processing_dir$file"

        # # Move file to the new destination
        aws s3 mv "${file_path}" "${dest_path}"

        if [ $? -eq 0 ]; then
                log "Succeed: Moved \"$file_path\" to \"$dest_path\""
                processible_paths+=("$file")
        else
                log "Failed: Failed to move \"$file_path\" to \"$dest_path\""
        fi
done


# Define the source and target directories
# src_dir="/root/SCRIPTS/tmp/"
target_dir="/root/IMPORTS/"

# Ensure directories exist
# mkdir -p "$src_dir"
mkdir -p "$target_dir"

log "Directories ensured"


# Process each file
for file in "${processible_paths[@]}"; do
        local_path="$target_dir$file"
        dest_path="s3://infinity-91872/$processing_dir$file"

        # Download the file from S3 to the local target directory
        aws s3 cp "${dest_path}" "$local_path"
        if [ $? -eq 0 ]; then
                log "Downloaded \"$file\" to local processing directory"

                # If the file exists locally, proceed with mautic
                if [ -f "$local_path" ]; then
                        log "Starting import for file $file"

                        # Run the AMS import command
                        php /var/www/ams/bin/console mautic:import:directory >> "$log_file" 2>&1
                        php /var/www/ams/bin/console mautic:import >> "$log_file" 2>&1
                        log "Import finished for file $file"

                        # I don't know why it is necessary but delete the s3 bucket file
                        if aws s3 rm "${dest_path}"; then
                                log "Deleted original file $file"
                        else
                                log "Failed to delete original s3 object $file"
                        fi
                        # Optionally, delete the local file after processing
                        # rm "$local_path"
                else
                        log "File not found for processing : $file"
                fi
        else
                log "Failed to download \"$file\" from S3 to local processing directory"
        fi
done

log "Script execution completed."