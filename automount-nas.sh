#!/bin/bash

###############################################################################
# NAS Automount Utility for macOS
# 
# This script checks if a NAS is mounted and attempts to mount it if not.
# It can be run manually, via cron, or using launchd for automatic monitoring.
###############################################################################

set -u

# Configuration file location (can be overridden with -c flag)
CONFIG_FILE="${HOME}/.automount.conf"

# Default values (will be overridden by config file)
NAS_SHARE=""
MOUNT_POINT=""
NAS_USERNAME=""
NAS_PASSWORD=""
LOG_FILE="${HOME}/Library/Logs/automount-nas.log"
NOTIFY_ON_SUCCESS=false
NOTIFY_ON_FAILURE=true
MAX_LOG_LINES=1000

# Script version
VERSION="1.0.0"

###############################################################################
# Functions
###############################################################################

# Print usage information
usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

NAS Automount Utility for macOS - Automatically mount network shares

OPTIONS:
    -c FILE     Use alternate configuration file (default: ~/.automount.conf)
    -h          Show this help message
    -v          Show version information
    -t          Test mode: check mount status without attempting to mount
    -d          Debug mode: show verbose output

CONFIGURATION:
    Create a configuration file at ~/.automount.conf with the following format:
    
    NAS_SHARE="smb://nas-server/share"
    MOUNT_POINT="/Volumes/NAS"
    NAS_USERNAME="your-username"
    NAS_PASSWORD="your-password"
    LOG_FILE="${HOME}/Library/Logs/automount-nas.log"
    NOTIFY_ON_SUCCESS=false
    NOTIFY_ON_FAILURE=true

EXAMPLES:
    $(basename "$0")              # Run with default config
    $(basename "$0") -t           # Test mode only
    $(basename "$0") -c ~/.nas.conf  # Use custom config file

EOF
    exit 0
}

# Print version information
version() {
    echo "NAS Automount Utility v${VERSION}"
    exit 0
}

# Log message with timestamp
log_message() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[${timestamp}] [${level}] ${message}" >> "${LOG_FILE}"
    
    if [[ "${DEBUG_MODE}" == "true" ]]; then
        echo "[${timestamp}] [${level}] ${message}"
    fi
    
    # Rotate log if it gets too large
    rotate_log
}

# Rotate log file if it exceeds MAX_LOG_LINES
rotate_log() {
    if [[ -f "${LOG_FILE}" ]]; then
        local line_count
        line_count=$(wc -l < "${LOG_FILE}" 2>/dev/null || echo 0)
        if [[ ${line_count} -gt ${MAX_LOG_LINES} ]]; then
            tail -n 500 "${LOG_FILE}" > "${LOG_FILE}.tmp"
            mv "${LOG_FILE}.tmp" "${LOG_FILE}"
            log_message "INFO" "Log rotated (was ${line_count} lines)"
        fi
    fi
}

# Send notification to user
send_notification() {
    local title="$1"
    local message="$2"
    local sound="${3:-default}"
    
    # Use osascript to send macOS notification
    if command -v osascript &> /dev/null; then
        osascript -e "display notification \"${message}\" with title \"${title}\" sound name \"${sound}\""
    fi
}

# Check if NAS is currently mounted
is_mounted() {
    local mount_point="$1"
    
    if mount | grep -q "on ${mount_point} "; then
        return 0
    else
        return 1
    fi
}

# Attempt to mount the NAS
mount_nas() {
    local share="$1"
    local mount_point="$2"
    local username="$3"
    local password="$4"
    
    log_message "INFO" "Attempting to mount ${share} to ${mount_point}"
    
    # Create mount point if it doesn't exist
    if [[ ! -d "${mount_point}" ]]; then
        log_message "INFO" "Creating mount point: ${mount_point}"
        mkdir -p "${mount_point}" 2>&1 | while read -r line; do log_message "DEBUG" "$line"; done
        
        if [[ ! -d "${mount_point}" ]]; then
            log_message "ERROR" "Failed to create mount point: ${mount_point}"
            return 1
        fi
    fi
    
    # Build mount command
    local mount_url="${share}"
    
    # Add credentials to URL if provided
    if [[ -n "${username}" ]]; then
        # Extract protocol and path
        local protocol="${share%%://*}"
        local path="${share#*://}"
        
        if [[ -n "${password}" ]]; then
            mount_url="${protocol}://${username}:${password}@${path}"
        else
            mount_url="${protocol}://${username}@${path}"
        fi
    fi
    
    # Attempt to mount using mount_smbfs
    local mount_output
    mount_output=$(mount -t smbfs "${mount_url}" "${mount_point}" 2>&1)
    local mount_result=$?
    
    if [[ ${mount_result} -eq 0 ]]; then
        log_message "INFO" "Successfully mounted ${share} to ${mount_point}"
        return 0
    else
        log_message "ERROR" "Failed to mount ${share}: ${mount_output}"
        return 1
    fi
}

# Main function
main() {
    local test_mode=false
    
    # Parse command line arguments
    while getopts "c:hvtd" opt; do
        case ${opt} in
            c)
                CONFIG_FILE="${OPTARG}"
                ;;
            h)
                usage
                ;;
            v)
                version
                ;;
            t)
                test_mode=true
                ;;
            d)
                DEBUG_MODE=true
                ;;
            *)
                usage
                ;;
        esac
    done
    
    # Load configuration file
    if [[ ! -f "${CONFIG_FILE}" ]]; then
        echo "ERROR: Configuration file not found: ${CONFIG_FILE}" >&2
        echo "Please create a configuration file. Use -h for help." >&2
        exit 1
    fi
    
    # Source the configuration file
    # shellcheck source=/dev/null
    source "${CONFIG_FILE}"
    
    # Validate required configuration
    if [[ -z "${NAS_SHARE}" || -z "${MOUNT_POINT}" ]]; then
        echo "ERROR: NAS_SHARE and MOUNT_POINT must be set in ${CONFIG_FILE}" >&2
        exit 1
    fi
    
    # Ensure log directory exists
    local log_dir
    log_dir=$(dirname "${LOG_FILE}")
    mkdir -p "${log_dir}"
    
    # Check if already mounted
    if is_mounted "${MOUNT_POINT}"; then
        log_message "INFO" "NAS is already mounted at ${MOUNT_POINT}"
        if [[ "${test_mode}" == "true" ]]; then
            echo "✓ NAS is mounted at ${MOUNT_POINT}"
        fi
        exit 0
    fi
    
    # Not mounted - log and attempt to mount (unless in test mode)
    log_message "WARN" "NAS is not mounted at ${MOUNT_POINT}"
    
    if [[ "${test_mode}" == "true" ]]; then
        echo "✗ NAS is NOT mounted at ${MOUNT_POINT}"
        exit 1
    fi
    
    # Attempt to mount
    if mount_nas "${NAS_SHARE}" "${MOUNT_POINT}" "${NAS_USERNAME}" "${NAS_PASSWORD}"; then
        if [[ "${NOTIFY_ON_SUCCESS}" == "true" ]]; then
            send_notification "NAS Mounted" "Successfully mounted ${NAS_SHARE}" "Glass"
        fi
        exit 0
    else
        if [[ "${NOTIFY_ON_FAILURE}" == "true" ]]; then
            send_notification "NAS Mount Failed" "Failed to mount ${NAS_SHARE}" "Basso"
        fi
        exit 1
    fi
}

# Initialize DEBUG_MODE
DEBUG_MODE=false

# Run main function
main "$@"
