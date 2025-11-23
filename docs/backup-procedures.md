# Backup Procedures

## Overview

This document outlines the backup strategy and procedures for the Tabiri Homelab environment. Regular backups are essential for disaster recovery and data protection.

## Backup Strategy

### Backup Tiers

#### Tier 1: Critical Data
- **Frequency**: Daily
- **Retention**: 30 days
- **Scope**: Configuration files, databases, service state
- **Services**: NetBird VPN, Identity Provider, Reverse Proxy

#### Tier 2: Important Data
- **Frequency**: Weekly
- **Retention**: 90 days
- **Scope**: Application data, user content
- **Services**: NextCloud, Airflow, Semaphore

#### Tier 3: Optional Data
- **Frequency**: Monthly
- **Retention**: 1 year
- **Scope**: Logs, temporary files, cache data
- **Services**: Monitoring data, application logs

## Backup Components

### 1. Configuration Files
- Docker Compose files
- Environment variables
- Service configuration files
- Terraform state and configuration

### 2. Database Backups
- PostgreSQL databases (Zitadel, NextCloud, Airflow)
- SQLite databases (Nginx Proxy Manager)
- Application-specific databases

### 3. Application Data
- NextCloud user files and metadata
- Airflow DAGs and task history
- Semaphore projects and templates
- JDownloader downloads and configuration

### 4. Service State
- Docker volumes
- Service metadata
- Network configurations
- SSL certificates

## Backup Scripts

### NetBird VPN Backup
```bash
# Location: scripts/backup/backup-netbird.sh
# Usage: ./backup-netbird.sh [backup_directory]

# Example:
./scripts/backup/backup-netbird.sh /home/ec2-user/backups
```

**What it backs up:**
- Docker Compose configuration
- Management service database
- Zitadel identity provider data
- Caddy reverse proxy configuration
- SSL certificates and keys

**Restoration:**
```bash
./scripts/backup/restore-netbird.sh /home/ec2-user/backups/netbird_backup_20250101_120000
```

### Verification Script
```bash
# Verify backup integrity
./scripts/backup/verify-netbird-backup.sh /home/ec2-user/backups/netbird_backup_20250101_120000

# Quick verification (skips volume extraction)
./scripts/backup/verify-netbird-backup.sh /home/ec2-user/backups/netbird_backup_20250101_120000 --quick
```

## Automated Backup Schedule

### Cron Jobs
```bash
# Daily NetBird backup at 2 AM
0 2 * * * /home/ec2-user/tabiri-homelab/scripts/backup/backup-netbird.sh /home/ec2-user/backups

# Weekly full backup on Sundays at 3 AM
0 3 * * 0 /home/ec2-user/tabiri-homelab/scripts/backup/backup-all.sh /home/ec2-user/backups

# Monthly verification on first day of month at 4 AM
0 4 1 * * /home/ec2-user/tabiri-homelab/scripts/backup/verify-all-backups.sh
```

### Systemd Timers (Alternative)
```ini
# /etc/systemd/system/backup-netbird.timer
[Unit]
Description=Daily NetBird Backup
Requires=backup-netbird.service

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
```

## Backup Storage

### Local Storage
- Primary location: `/home/ec2-user/backups`
- Retention: 30 days for daily, 90 days for weekly
- Compression: Yes (tar.gz format)
- Encryption: Optional (for sensitive data)

### Cloud Storage (Optional)
- AWS S3 with versioning
- Backblaze B2
- Google Cloud Storage
- Encrypted before upload

### Backup Rotation
```bash
# Cleanup old backups (run by backup scripts)
find /home/ec2-user/backups -name "netbird_backup_*" -type d -mtime +30 -exec rm -rf {} \;
find /home/ec2-user/backups -name "full_backup_*" -type d -mtime +90 -exec rm -rf {} \;
```

## Service-Specific Backup Procedures

### NetBird VPN
**Critical Components:**
- Management service database (`/var/lib/netbird`)
- Zitadel identity provider data
- Configuration files
- SSL certificates

**Backup Command:**
```bash
cd services/netbird
./scripts/backup/backup-netbird.sh
```

### NextCloud
**Critical Components:**
- User files and data
- Database (PostgreSQL)
- Configuration files
- Apps and themes

**Backup Procedure:**
```bash
# Database backup
docker-compose exec nextcloud-db pg_dump -U nextcloud nextcloud > nextcloud_backup_$(date +%Y%m%d).sql

# File backup
tar -czf nextcloud_data_$(date +%Y%m%d).tar.gz nextcloud/data/
```

### Airflow
**Critical Components:**
- PostgreSQL database
- DAG files
- Connection configurations
- Variable store

**Backup Procedure:**
```bash
# Database backup
docker-compose exec airflow-db pg_dump -U airflow airflow > airflow_backup_$(date +%Y%m%d).sql

# DAG files backup
tar -czf airflow_dags_$(date +%Y%m%d).tar.gz airflow/dags/
```

### Monitoring Stack
**Critical Components:**
- Prometheus data
- Grafana dashboards
- Alert configurations

**Backup Procedure:**
```bash
# Prometheus data (if persistence is needed)
tar -czf prometheus_data_$(date +%Y%m%d).tar.gz prometheus/data/

# Grafana configuration
docker-compose exec grafana tar -czf /tmp/grafana_backup.tar.gz /etc/grafana/
```

## Disaster Recovery

### Recovery Scenarios

#### Complete System Failure
1. Provision new infrastructure using Terraform
2. Restore NetBird VPN from backup
3. Restore other services in dependency order
4. Verify connectivity and functionality

#### Partial Service Failure
1. Identify affected service
2. Stop the service
3. Restore from latest backup
4. Restart service and verify

#### Data Corruption
1. Identify corruption scope
2. Restore affected data from backup
3. Validate data integrity
4. Monitor for recurrence

### Recovery Time Objectives (RTO)
- **Critical Services**: 4 hours (NetBird, Reverse Proxy)
- **Important Services**: 8 hours (NextCloud, Airflow)
- **Non-critical Services**: 24 hours (Monitoring, Downloaders)

### Recovery Point Objectives (RPO)
- **Critical Data**: 24 hours
- **Important Data**: 7 days
- **Archival Data**: 30 days

## Testing and Validation

### Regular Testing Schedule
- **Weekly**: Verify backup integrity
- **Monthly**: Test restoration of one service
- **Quarterly**: Full disaster recovery drill
- **Annually**: Comprehensive backup strategy review

### Testing Procedures
```bash
# 1. Verify backup integrity
./scripts/backup/verify-netbird-backup.sh /backup/path

# 2. Test restoration in isolated environment
./scripts/backup/restore-netbird.sh /backup/path --test-mode

# 3. Validate service functionality
curl -f https://netbird.your-domain.com/health
```

### Success Criteria
- Backup files are not corrupted
- Restoration completes without errors
- Services start successfully after restoration
- Data integrity is maintained
- All functionality is restored

## Monitoring and Alerting

### Backup Monitoring
- Backup completion status
- Backup file size anomalies
- Storage space availability
- Backup duration monitoring

### Alert Conditions
- Backup failure
- Backup size significantly different from average
- Storage space below threshold
- Backup duration exceeds expected time

### Notification Channels
- Email alerts
- Slack/Teams notifications
- SMS alerts (for critical failures)
- Dashboard indicators

## Security Considerations

### Backup Encryption
```bash
# Encrypt sensitive backups
gpg --symmetric --cipher-algo AES256 backup_file.tar.gz

# Decrypt for restoration
gpg --decrypt backup_file.tar.gz.gpg > backup_file.tar.gz
```

### Access Control
- Limit backup file permissions
- Use secure transfer protocols
- Encrypt backups containing sensitive data
- Regular access reviews

### Secure Storage
- Isolated backup storage
- Off-site copies for critical data
- Versioning to prevent ransomware
- Immutable backups where possible

## Troubleshooting

### Common Issues

#### Backup Failures
- **Insufficient disk space**: Monitor storage and clean old backups
- **Permission denied**: Run with appropriate privileges
- **Service not running**: Check service status before backup
- **Network issues**: Verify connectivity to storage

#### Restoration Issues
- **Version mismatch**: Ensure backup matches current version
- **Configuration conflicts**: Review restored configuration files
- **Database corruption**: Verify database backup integrity
- **Missing dependencies**: Check service dependencies

### Debugging Steps
1. Check backup logs for errors
2. Verify backup file integrity
3. Test restoration in isolated environment
4. Review system resources during backup
5. Check network connectivity

## Maintenance and Updates

### Regular Maintenance
- **Weekly**: Review backup logs and success rates
- **Monthly**: Update backup scripts and procedures
- **Quarterly**: Test disaster recovery procedures
- **Annually**: Review and update backup strategy

### Version Compatibility
- Document software versions in backups
- Test restoration with new versions
- Maintain backward compatibility where possible
- Update procedures when technologies change

### Documentation Updates
- Update this document when procedures change
- Document lessons learned from recovery tests
- Maintain runbooks for common scenarios
- Keep contact information current

## Emergency Contacts

### Technical Contacts
- Primary: [Your Name] - [Phone/Email]
- Secondary: [Backup Contact] - [Phone/Email]
- Infrastructure: [Cloud Provider Support]

### Escalation Procedures
1. Initial issue detection and assessment
2. Primary contact notification
3. Secondary contact escalation (if no response in 30 minutes)
4. Management notification (for critical outages)
5. External support engagement (if required)

This backup procedures document provides a comprehensive framework for protecting your homelab data and ensuring quick recovery from incidents. Regular testing and updates are essential for maintaining an effective backup strategy.
