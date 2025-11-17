#!/bin/bash
# NetBird restoration script (official method)
# Usage: Set the correct timestamp and run on the target server after copying backup files

set -e

backup_dir="/root/ec2-user/backup2"
timestamp="20251023_012950"  # Set this to match the backup you want to restore
backup_dir_ts="$backup_dir/netbird_backup_$timestamp"

echo "[1/4] Restoring NetBird configuration files..."
config_files=(
  docker-compose.yml
  Caddyfile
  zitadel.env
  dashboard.env
  turnserver.conf
  management.json
  relay.env
  zdb.env
)
for f in "${config_files[@]}"; do
  if [ -f "$backup_dir_ts/$f" ]; then
    cp "$backup_dir_ts/$f" ./
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
  docker compose cp "$backup_dir_ts/netbird_management_db/." management:/var/lib/netbird/
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
for volume in "${volumes[@]}"; do
  archive="${volumes_backup_dir}/${volume}_backup_${timestamp}.tar.gz"
  echo "  Restoring volume: $volume from $archive"
  if [ -f "$archive" ]; then
    docker run --rm -v "$volume":/volume -v "$volumes_backup_dir":/backup alpine \
      sh -c "cd /volume && tar -xzf /backup/$(basename $archive)"
    echo "    Volume $volume restored"
  else
    echo "    Archive $archive not found, skipping $volume" >&2
  fi
done

# echo "[4/4] Zitadel DB restore (CockroachDB) - manual step required!"
# echo "  If you use CockroachDB for Zitadel, run the following command inside the CockroachDB container or on the DB host:"
# echo "    cockroach sql --certs-dir=certs --host=<host> -e 'RESTORE FROM \"nodelocal://1/backup_$timestamp\";'"
# echo "  See: https://www.cockroachlabs.com/docs/stable/restore for details."

echo "Restoration completed: $backup_dir_ts"
