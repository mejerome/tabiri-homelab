# NetBird VM Backup and Restore Procedures

This document outlines the procedures for backing up and restoring your NetBird VPN deployment.

## Backup Overview

The backup strategy includes:
1. Terraform state files
2. Docker volume data
3. Configuration files
4. Database backups (Zitadel)

## Automated Backup Scripts

The `backup-restore/` directory contains scripts for automated backup and restore operations.

### backup_netbird.sh

This script performs the following operations:
- Creates a timestamped backup directory
- Exports Docker volumes for persistent data
- Saves configuration files
- Exports the Zitadel database
- Compresses the backup into a tar.gz file

Usage:
```bash
./backup-restore/backup_netbird.sh
```

### restore_netbird.sh

This script restores a previous backup:
- Stops all Docker services
- Restores Docker volumes from backup
- Recreates configuration files
- Restores the Zitadel database
- Restarts Docker services

Usage:
```bash
./backup-restore/restore_netbird.sh [backup-file.tar.gz]
```

## Manual Backup Procedures

### 1. Terraform State Backup

Terraform automatically maintains a backup of the state file (`terraform.tfstate.backup`). For additional safety:

```bash
# Copy current state to a safe location
cp terraform.tfstate /secure/backup/location/
```

### 2. Docker Volume Backup

To manually backup Docker volumes:

```bash
# List volumes
docker volume ls

# Backup specific volumes
docker run --rm -v netbird_management:/source -v $(pwd):/backup alpine tar czf /backup/netbird_management.tar.gz -C /source .
```

### 3. Configuration Files Backup

Backup all configuration files:

```bash
tar czf netbird-configs.tar.gz *.env *.json Caddyfile turnserver.conf
```

## Restore Procedures

### From Automated Backup

1. Identify the backup file to restore
2. Run the restore script:
   ```bash
   ./backup-restore/restore_netbird.sh backup-file.tar.gz
   ```

### Manual Restore

1. Stop Docker services:
   ```bash
   docker-compose down
   ```

2. Restore Docker volumes:
   ```bash
   # Create volume if it doesn't exist
   docker volume create netbird_management
   
   # Restore data
   docker run --rm -v netbird_management:/target -v $(pwd):/backup alpine sh -c "cd /target && tar xzf /backup/netbird_management.tar.gz --strip 1"
   ```

3. Restore configuration files:
   ```bash
   tar xzf netbird-configs.tar.gz
   ```

4. Start services:
   ```bash
   docker-compose up -d
   ```

## Scheduling Regular Backups

Set up a cron job for automated backups:

```bash
# Edit crontab
crontab -e

# Add line for daily backup at 2 AM
0 2 * * * /path/to/netbird-vm/backup-restore/backup_netbird.sh
```

## Testing Backups

Regularly test your backups:
1. Perform a restore to a separate test environment
2. Verify all services start correctly
3. Confirm data integrity

It's recommended to test backups at least monthly.
