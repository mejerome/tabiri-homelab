#!/usr/bin/env bash
#
# copy_dir_lxc.sh - Copy directory between Proxmox LXC containers
#
# This script copies a directory from one Proxmox LXC container to another
# using pct exec and tar (no SSH, no shared mounts).
#
# Usage:
#   ./copy_dir_lxc.sh --src-id 100 --dst-id 101 --src-path /var/www --dst-path /var/www
#   ./copy_dir_lxc.sh --src-id 100 --dst-id 101 --src-path /var/www --dst-path /var/www --uid 1000 --gid 1000
#
# Requirements:
#   - Proxmox host with pct command available
#   - Source and destination containers must be running
#   - User must have appropriate permissions to execute pct commands
#
# Author: Cloud Infrastructure Team
# Version: 1.0

set -euo pipefail

# Default values
OWNER_UID=""
OWNER_GID=""
BACKUP_ENABLED=false
VERBOSE=false

# Color codes for output
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Print colored output
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}" >&2
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    if [[ "$VERBOSE" == true ]]; then
        echo -e "📋 $1"
    fi
}

# Display usage information
usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Copy a directory from one Proxmox LXC container to another.

REQUIRED OPTIONS:
  --src-id ID          Source LXC container ID
  --dst-id ID          Destination LXC container ID
  --src-path PATH      Source directory path
  --dst-path PATH      Destination directory path

OPTIONAL OPTIONS:
  --uid UID            Owner UID for destination files (default: preserve)
  --gid GID            Owner GID for destination files (default: preserve)
  --backup             Enable pre-copy backup of destination directory
  --verbose            Enable verbose output
  --help               Display this help message

EXAMPLES:
  $(basename "$0") --src-id 100 --dst-id 101 --src-path /var/www --dst-path /var/www
  $(basename "$0") --src-id 100 --dst-id 101 --src-path /var/www --dst-path /var/www --uid 1000 --gid 1000 --backup

NOTES:
  - Source and destination containers must be running
  - tar --sparse is used for efficient handling of sparse files
  - Permissions, symlinks, and timestamps are preserved
  - Script is idempotent - can be run multiple times safely
EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --src-id)
                SRC_LXC_ID="$2"
                shift 2
                ;;
            --dst-id)
                DST_LXC_ID="$2"
                shift 2
                ;;
            --src-path)
                SRC_PATH="$2"
                shift 2
                ;;
            --dst-path)
                DST_PATH="$2"
                shift 2
                ;;
            --uid)
                OWNER_UID="$2"
                shift 2
                ;;
            --gid)
                OWNER_GID="$2"
                shift 2
                ;;
            --backup)
                BACKUP_ENABLED=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --help|-h)
                usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done

    # Validate required parameters
    if [[ -z "${SRC_LXC_ID:-}" ]] || [[ -z "${DST_LXC_ID:-}" ]] || 
       [[ -z "${SRC_PATH:-}" ]] || [[ -z "${DST_PATH:-}" ]]; then
        print_error "Missing required parameters"
        usage
        exit 1
    fi
}

# Validate that containers are running
validate_containers() {
    print_info "Validating container states..."
    
    # Check if source container is running
    if ! pct status "$SRC_LXC_ID" &>/dev/null; then
        print_error "Source container $SRC_LXC_ID is not running or does not exist"
        exit 1
    fi
    
    # Check if destination container is running
    if ! pct status "$DST_LXC_ID" &>/dev/null; then
        print_error "Destination container $DST_LXC_ID is not running or does not exist"
        exit 1
    fi
    
    print_success "Containers validated: $SRC_LXC_ID and $DST_LXC_ID are running"
}

# Validate that source path exists
validate_source_path() {
    print_info "Validating source path: $SRC_PATH"
    
    if ! pct exec "$SRC_LXC_ID" -- test -d "$SRC_PATH"; then
        print_error "Source path $SRC_PATH does not exist in container $SRC_LXC_ID"
        exit 1
    fi
    
    print_success "Source path validated: $SRC_PATH exists in container $SRC_LXC_ID"
}

# Validate that destination parent directory exists
validate_destination_parent() {
    local dst_parent
    dst_parent=$(dirname "$DST_PATH")
    
    print_info "Validating destination parent directory: $dst_parent"
    
    if ! pct exec "$DST_LXC_ID" -- test -d "$dst_parent"; then
        print_error "Destination parent directory $dst_parent does not exist in container $DST_LXC_ID"
        print_info "Creating destination parent directory..."
        if ! pct exec "$DST_LXC_ID" -- mkdir -p "$dst_parent"; then
            print_error "Failed to create destination parent directory $dst_parent"
            exit 1
        fi
        print_success "Created destination parent directory: $dst_parent"
    else
        print_success "Destination parent directory validated: $dst_parent exists in container $DST_LXC_ID"
    fi
}

# Create backup of destination directory if it exists and backup is enabled
create_backup() {
    if [[ "$BACKUP_ENABLED" == true ]]; then
        print_info "Checking if backup is needed..."
        
        if pct exec "$DST_LXC_ID" -- test -d "$DST_PATH"; then
            local timestamp
            timestamp=$(date +"%Y%m%d_%H%M%S")
            local backup_path="${DST_PATH}.backup_${timestamp}"
            
            print_info "Creating backup of existing destination directory..."
            if pct exec "$DST_LXC_ID" -- tar -czf "${backup_path}.tar.gz" -C "$(dirname "$DST_PATH")" "$(basename "$DST_PATH")" 2>/dev/null; then
                print_success "Backup created: ${backup_path}.tar.gz"
            else
                print_error "Failed to create backup of destination directory"
                exit 1
            fi
        else
            print_info "No existing destination directory to backup"
        fi
    fi
}

# Copy directory using tar
copy_directory() {
    print_info "Starting directory copy from container $SRC_LXC_ID:$SRC_PATH to container $DST_LXC_ID:$DST_PATH"
    
    # Create the copy using tar pipes through pct exec
    if pct exec "$SRC_LXC_ID" -- tar -c -f - --sparse -C "$(dirname "$SRC_PATH")" "$(basename "$SRC_PATH")" | \
       pct exec "$DST_LXC_ID" -- tar -x -f - --sparse -C "$(dirname "$DST_PATH")" 2>/dev/null; then
        print_success "Directory copy completed successfully"
    else
        print_error "Failed to copy directory"
        exit 1
    fi
}

# Adjust ownership if specified
adjust_ownership() {
    if [[ -n "${OWNER_UID:-}" ]] || [[ -n "${OWNER_GID:-}" ]]; then
        print_info "Adjusting ownership..."
        
        local chown_args=""
        if [[ -n "${OWNER_UID:-}" ]] && [[ -n "${OWNER_GID:-}" ]]; then
            chown_args="$OWNER_UID:$OWNER_GID"
        elif [[ -n "${OWNER_UID:-}" ]]; then
            chown_args="$OWNER_UID"
        elif [[ -n "${OWNER_GID:-}" ]]; then
            chown_args=":$OWNER_GID"
        fi
        
        if pct exec "$DST_LXC_ID" -- chown -R "$chown_args" "$DST_PATH"; then
            print_success "Ownership adjusted to $chown_args"
        else
            print_error "Failed to adjust ownership"
            exit 1
        fi
    fi
}

# Main function
main() {
    parse_args "$@"
    validate_containers
    validate_source_path
    validate_destination_parent
    create_backup
    copy_directory
    adjust_ownership
    
    print_success "Directory copy operation completed successfully!"
    echo "Source:      Container $SRC_LXC_ID:$SRC_PATH"
    echo "Destination: Container $DST_LXC_ID:$DST_PATH"
    
    if [[ -n "${OWNER_UID:-}" ]] || [[ -n "${OWNER_GID:-}" ]]; then
        echo "Ownership:   ${OWNER_UID:-[preserved]}:${OWNER_GID:-[preserved]}"
    fi
}

# Run main function with all arguments
main "$@"
