#!/bin/bash
# Backup NetBird for migration or restore purposes (official method)

set -e

# Set backup directory and timestamp
backup_dir="/home/ec2-user/backup"
timestamp=$(date +"%Y%m%d_%H%M%S")
backup_dir_ts="$backup_dir/netbird_backup_$timestamp"

# Create backup directory
if ! mkdir -p "$backup_dir_ts"; then
  echo "Error: Could not create backup directory $backup_dir_ts" >&2
  exit 1
fi

echo "[1/4] Backing up NetBird configuration files..."
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
  if [ -f "$f" ]; then
    cp "$f" "$backup_dir_ts/"
    echo "  Backed up $f"
  else
    echo "  Warning: $f not found, skipping."
  fi
done

echo "[2/4] Backing up Management service database..."
echo "  Stopping management service..."
docker compose stop management
echo "  Copying /var/lib/netbird/ from management container..."
docker compose cp -a management:/var/lib/netbird/ "$backup_dir_ts/netbird_management_db/"
echo "  Starting management service..."
docker compose start management

echo "[3/4] Backing up Docker volumes (optional, for extra safety)..."
volumes=(
  "netbird_caddy_data"
  "netbird_management"
  "netbird_zdb_data"
  "netbird_zitadel_certs"
)
volumes_backup_dir="$backup_dir_ts/volumes"
if ! mkdir -p "$volumes_backup_dir"; then
  echo "Error: Could not create volumes backup directory $volumes_backup_dir" >&2
  exit 3
fi
for volume in "${volumes[@]}"; do
  echo "  Backing up volume: $volume"
  if docker run --rm -v "$volume":/volume -v "$volumes_backup_dir":/backup alpine \
    sh -c "cd /volume && tar -czf /backup/${volume}_backup_$timestamp.tar.gz ."; then
    echo "    Volume $volume backed up to $volumes_backup_dir/${volume}_backup_$timestamp.tar.gz"
  else
    echo "    Error backing up volume: $volume" >&2
  fi
done

echo "[4/4] Zitadel DB backup (CockroachDB) - manual step required!"
echo "  If you use CockroachDB for Zitadel, run the following command inside the CockroachDB container or on the DB host:"
echo "    cockroach sql --certs-dir=certs --host=<host> -e 'BACKUP TO \"nodelocal://1/backup_$timestamp\";'"
echo "  See: https://www.cockroachlabs.com/docs/stable/backup for details."

echo "Backup completed: $backup_dir_ts"