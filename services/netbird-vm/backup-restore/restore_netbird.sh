#!/bin/bash
#
# NetBird Restore Script
#
# This script restores a previous backup of the NetBird installation including:
# - Configuration files
# - Management service database
# - Docker volumes
# - Zitadel database (manual step)
#
# Usage:
#   ./restore_netbird.sh [timestamp]
#
# If no timestamp is provided, the script will list available backups
#
# Security Considerations:
# - This script will overwrite existing configuration files
# - This script will overwrite existing Docker volumes
# - Ensure you have a current backup before running this script
#

set -e

# Configuration
backup_base_dir="/home/ec2-user/backup"
timestamp="$1"

# If no timestamp provided, list available backups
if [ -z "$timestamp" ]; then
  echo "Available backups:"
  if ls ${backup_base_dir}/netbird_backup_* 2>/dev/null; then
    ls -d ${backup_base_dir}/netbird_backup_*
  else
    echo "  No backups found in $backup_base_dir"
  fi
  echo ""
  echo "Usage: $0 [timestamp]"
  echo "Example: $0 20251023_012950"
  exit 0
fi

backup_dir_ts="$backup_base_dir/netbird_backup_$timestamp"

# Check if backup exists
if [ ! -d "$backup_dir_ts" ]; then
  echo "Error: Backup directory $backup_dir_ts not found" >&2
  echo "Available backups:"
  ls -d ${backup_base_dir}/netbird_backup_* 2>/dev/null || echo "  No backups found"
  exit 1
fi

echo "Restoring NetBird from backup: $backup_dir_ts"
echo ""
echo "WARNING: This will overwrite existing configuration files and Docker volumes."
echo "Ensure you have a current backup before proceeding."
echo ""
read -p "Continue with restore? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Restore cancelled."
  exit 0
fi

echo "[1/4] Restoring NetBird configuration files..."
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

for f in "${config_files[@]}"; do
  if [ -f "$backup_dir_ts/$f" ]; then
    cp "$backup_dir_ts/$f" ./
    chmod 600 "$f"  # Secure permissions
    echo "  Restored $f"
  else
    echo "  Warning: $f not found in backup, skipping."
  fi
done

echo "[2/4] Restoring Management service database..."
if [ -d "$backup_dir_ts/netbird_management_db" ]; then
  echo "  Stopping management service..."
  docker compose stop management
  
  echo "  Copying management DB to Docker volume..."
  # Remove existing data in the volume (be careful!)
  docker compose run --rm --entrypoint sh management -c "rm -rf /var/lib/netbird/*"
  
  # Copy backup data to volume
  docker compose cp "$backup_dir_ts/netbird_management_db/." management:/var/lib/netbird/
  
  # Set proper permissions
  docker compose run --rm --entrypoint sh management -c "chown -R 65532:65532 /var/lib/netbird"
  
  echo "  Starting management service..."
  docker compose start management
else
  echo "  Management DB backup not found, skipping."
fi

echo "[3/4] Restoring Docker volumes (optional, for extra safety)..."
volumes=(
  "netbird_caddy_data"
  "netbird_management"
  "netbird_zdb_data"
  "netbird_zitadel_certs"
)

volumes_backup_dir="$backup_dir_ts/volumes"
if [ -d "$volumes_backup_dir" ]; then
  for volume in "${volumes[@]}"; do
    archive="${volumes_backup_dir}/${volume}_backup_${timestamp}.tar.gz"
    echo "  Restoring volume: $volume from $archive"
    if [ -f "$archive" ]; then
      # Clear the volume first for clean restore
      docker run --rm -v "$volume":/volume alpine sh -c "rm -rf /volume/*"
      
      # Restore from archive
      docker run --rm -v "$volume":/volume -v "$volumes_backup_dir":/backup alpine \
        sh -c "cd /volume && tar -xzf /backup/$(basename $archive)"
      
      echo "    Volume $volume restored"
    else
      echo "    Archive $archive not found, skipping $volume" >&2
    fi
  done
else
  echo "  Volumes backup directory not found, skipping volume restoration."
fi

echo "[4/4] Zitadel DB restore information..."
echo "  Note: If you use CockroachDB for Zitadel, run the following command inside the CockroachDB container:"
echo "    cockroach sql --certs-dir=certs --host=<host> -e 'RESTORE FROM \"nodelocal://1/backup_$timestamp\";'"
echo "  See: https://www.cockroachlabs.com/docs/stable/restore for details."

echo ""
echo "Restore completed: $backup_dir_ts"
echo ""
echo "Next Steps:"
echo "1. Verify all services are running correctly: docker compose ps"
echo "2. Check service logs for any errors: docker compose logs"
echo "3. Test connectivity to your NetBird instance"
echo ""
echo "Security Notes:"
echo "- Review all configuration files for correctness"
echo "- Ensure proper file permissions on restored files"
echo "- Verify no sensitive information was exposed during restore process"
