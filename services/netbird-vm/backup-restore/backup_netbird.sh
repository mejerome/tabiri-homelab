#!/bin/bash
#
# NetBird Backup Script
#
# This script creates a backup of the NetBird installation including:
# - Configuration files
# - Management service database
# - Docker volumes
# - Zitadel database (manual step)
#
# Usage:
#   ./backup_netbird.sh
#
# The script will create a timestamped backup directory in /home/ec2-user/backup/
#
# Security Considerations:
# - Backups are not encrypted by default
# - Ensure backup directory has proper permissions (700)
# - Consider encrypting backups before storing offsite
#

set -e

# Configuration
backup_base_dir="/home/ec2-user/backup"
timestamp=$(date +"%Y%m%d_%H%M%S")
backup_dir="${backup_base_dir}/netbird_backup_${timestamp}"

# Ensure backup directory exists with secure permissions
if ! mkdir -p "$backup_base_dir"; then
  echo "Error: Could not create backup base directory $backup_base_dir" >&2
  exit 1
fi

# Set secure permissions on backup base directory
chmod 700 "$backup_base_dir"

# Create timestamped backup directory
if ! mkdir -p "$backup_dir"; then
  echo "Error: Could not create backup directory $backup_dir" >&2
  exit 1
fi

# Set secure permissions on backup directory
chmod 700 "$backup_dir"

echo "[1/4] Backing up NetBird configuration files..."

# Configuration files to backup
config_files=(
  "docker-compose.yml"
  "Caddyfile"
  "zitadel.env"
  "dashboard.env"
  "turnserver.conf"
  "management.json"
  "relay.env"
  "zdb.env"
)

# Backup configuration files
for file in "${config_files[@]}"; do
  if [ -f "$file" ]; then
    cp "$file" "$backup_dir/"
    chmod 600 "$backup_dir/$file"  # Secure permissions for config files
    echo "  Backed up $file"
  else
    echo "  Warning: $file not found, skipping."
  fi
done

echo "[2/4] Backing up Management service database..."
echo "  Stopping management service..."
docker compose stop management

echo "  Copying /var/lib/netbird/ from management container..."
if docker compose cp -a management:/var/lib/netbird/ "$backup_dir/netbird_management_db/"; then
  chmod -R 600 "$backup_dir/netbird_management_db/"  # Secure permissions
  echo "  Management database backed up successfully"
else
  echo "  Error: Failed to backup management database" >&2
fi

echo "  Starting management service..."
docker compose start management

echo "[3/4] Backing up Docker volumes (optional, for extra safety)..."

# Docker volumes to backup
volumes=(
  "netbird_caddy_data"
  "netbird_management"
  "netbird_zdb_data"
  "netbird_zitadel_certs"
)

volumes_backup_dir="$backup_dir/volumes"
if ! mkdir -p "$volumes_backup_dir"; then
  echo "Error: Could not create volumes backup directory $volumes_backup_dir" >&2
  exit 3
fi

chmod 700 "$volumes_backup_dir"  # Secure permissions

for volume in "${volumes[@]}"; do
  echo "  Backing up volume: $volume"
  archive_name="${volume}_backup_${timestamp}.tar.gz"
  
  if docker run --rm -v "$volume":/volume -v "$volumes_backup_dir":/backup alpine \
    sh -c "cd /volume && tar -czf /backup/${archive_name} ." 2>/dev/null; then
    
    chmod 600 "$volumes_backup_dir/${archive_name}"  # Secure permissions
    echo "    Volume $volume backed up to $volumes_backup_dir/${archive_name}"
  else
    echo "    Error backing up volume: $volume" >&2
  fi
done

echo "[4/4] Zitadel DB backup information..."
echo "  Note: If you use CockroachDB for Zitadel, run the following command inside the CockroachDB container:"
echo "    cockroach sql --certs-dir=certs --host=<host> -e 'BACKUP TO \"nodelocal://1/backup_${timestamp}\";'"
echo "  See: https://www.cockroachlabs.com/docs/stable/backup for details."

echo ""
echo "Backup completed successfully!"
echo "Location: $backup_dir"
echo ""
echo "Security Notes:"
echo "- Backup files contain sensitive information"
echo "- Consider encrypting backups before storing offsite"
echo "- Ensure proper access controls on backup directory"
