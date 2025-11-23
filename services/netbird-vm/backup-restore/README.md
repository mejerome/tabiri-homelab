# NetBird Backup and Restore Procedures

This directory contains scripts and documentation for backing up and restoring your NetBird VPN installation.

## Overview

The backup and restore scripts handle:
- Configuration files
- Management service database
- Docker volumes
- Zitadel database (manual step)

## Backup Script

### Usage
```bash
./backup_netbird.sh
```

### What it Backs Up
1. Configuration files:
   - docker-compose.yml
   - Caddyfile
   - .env files
   - turnserver.conf
   - management.json

2. Management service database from Docker volume

3. All Docker volumes (as archives)

4. Instructions for Zitadel database backup

### Security Considerations
- Backups contain sensitive information
- Backups are not encrypted by default
- Store backups in secure, access-controlled locations
- Consider encrypting backups before storing offsite

## Restore Script

### Usage
List available backups:
```bash
./restore_netbird.sh
```

Restore a specific backup:
```bash
./restore_netbird.sh TIMESTAMP
```

### What it Restores
1. Configuration files (overwrites existing)
2. Management service database
3. Docker volumes
4. Instructions for Zitadel database restore

### Security Considerations
- This script will overwrite existing files and data
- Ensure you have a current backup before running
- Review all restored configuration files for correctness
- Verify proper file permissions after restore

## Scheduling Regular Backups

To schedule automated backups, add a cron job:

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

## Security Best Practices

1. **Encrypt Backups**: Use tools like GPG to encrypt backup files before storing offsite
2. **Access Controls**: Ensure backup directories have proper permissions (700 for directories, 600 for files)
3. **Retention Policy**: Implement a backup retention policy to avoid keeping unnecessary old backups
4. **Offsite Storage**: Store backups in geographically separate locations
5. **Regular Testing**: Test backups regularly to ensure they can be restored successfully
