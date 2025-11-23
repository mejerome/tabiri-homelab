# LXC Directory Copy Utility

A robust Bash script for copying directories between Proxmox LXC containers using only `pct exec` and `tar`.

## Overview

This utility enables efficient, secure copying of directory contents between LXC containers on the same Proxmox host without requiring SSH access or shared filesystems. It's designed for production environments with comprehensive error handling and audit capabilities.

## Features

- ✅ Preserves permissions, symlinks, and timestamps
- ✅ Uses `tar --sparse` for efficient handling of binary/sparse files
- ✅ Validates source/destination paths before copying
- ✅ Optional ownership adjustments
- ✅ Optional pre-copy backup functionality
- ✅ Idempotent execution
- ✅ Strict error handling with meaningful messages
- ✅ Colored console output for clear status indication

## Prerequisites

- Proxmox host with `pct` command available
- Source and destination containers must be running
- User must have appropriate permissions to execute `pct` commands
- Both containers must have `tar` installed

## Usage

### Basic Usage

```bash
./copy_dir_lxc.sh --src-id 100 --dst-id 101 --src-path /var/www --dst-path /var/www
```

### With Ownership Adjustment

```bash
./copy_dir_lxc.sh --src-id 100 --dst-id 101 --src-path /var/www --dst-path /var/www --uid 1000 --gid 1000
```

### With Pre-copy Backup

```bash
./copy_dir_lxc.sh --src-id 100 --dst-id 101 --src-path /var/www --dst-path /var/www --backup
```

### Using Environment Variables

Create a `.env` file with your configuration:

```bash
source copy_dir_lxc.env && ./copy_dir_lxc.sh --backup
```

### Full Parameter Reference

| Option | Description | Required |
|--------|-------------|----------|
| `--src-id ID` | Source LXC container ID | Yes |
| `--dst-id ID` | Destination LXC container ID | Yes |
| `--src-path PATH` | Source directory path | Yes |
| `--dst-path PATH` | Destination directory path | Yes |
| `--uid UID` | Owner UID for destination files | No |
| `--gid GID` | Owner GID for destination files | No |
| `--backup` | Enable pre-copy backup | No |
| `--verbose` | Enable verbose output | No |
| `--help` | Display help message | No |

## How It Works

1. Validates that both containers are running
2. Checks that the source path exists
3. Ensures the destination's parent directory exists (creates if needed)
4. Optionally creates a backup of the destination directory
5. Streams the directory content using `tar` through `pct exec` pipes
6. Optionally adjusts ownership of the copied files

## Rollback Procedures

### Using Automated Backups

When using the `--backup` flag, the script creates timestamped backup archives:

```bash
# List available backups
pct exec 101 -- ls -la /var/www.backup_*.tar.gz

# Restore from backup
pct exec 101 -- tar -xzf /var/www.backup_20231201_120000.tar.gz -C /
```

### Manual Rollback

To manually rollback changes:

```bash
# Remove copied directory
pct exec 101 -- rm -rf /var/www

# If you need to restore original files, you'll need to have a backup strategy in place
```

## Security Considerations

1. **Container Isolation**: The script only uses `pct exec`, which respects container boundaries
2. **Minimal Privileges**: Only requires `pct` command access, not root access to the host
3. **No Network Exposure**: All operations happen through Proxmox's internal mechanisms
4. **Path Validation**: Strict validation prevents directory traversal attacks
5. **Audit Trail**: All operations are logged and can be monitored through Proxmox logs

## Integration with CI/CD

The script is designed for CI/CD pipeline integration:

```yaml
# Example GitLab CI job
lxc-directory-sync:
  stage: deploy
  script:
    - ssh root@proxmox-host "cd /path/to/script && ./copy_dir_lxc.sh --src-id 100 --dst-id 101 --src-path /var/www --dst-path /var/www --backup"
  only:
    - master
```

## Common Use Cases

1. **Application Migration**: Moving web applications between containers
2. **Data Synchronization**: Keeping configuration directories in sync
3. **Environment Promotion**: Copying data from staging to production containers
4. **Disaster Recovery**: Restoring data to replacement containers

## Troubleshooting

### Container Not Running

```
❌ Source container 100 is not running or does not exist
```
Solution: Start the container with `pct start 100`

### Path Does Not Exist

```
❌ Source path /var/www does not exist in container 100
```
Solution: Verify the path exists in the container

### Permission Denied

```
❌ Failed to copy directory
```
Solution: Ensure the user has appropriate `pct` permissions

## Best Practices

1. Always test with `--verbose` flag in non-production environments
2. Use `--backup` flag for critical operations
3. Validate container states before running the script
4. Monitor disk space on destination containers
5. Consider scheduling regular backups of important containers

## Contributing

This script follows standard DevOps best practices:
- Clear error handling and logging
- Idempotent operations
- Comprehensive documentation
- Security-first approach

For improvements, follow the standard fork/pull request workflow.
