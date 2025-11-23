# Deployment Guide

## Prerequisites

### Required Tools
- **Docker & Docker Compose**: Container runtime and orchestration
- **Terraform** (v1.5.7+): Infrastructure as Code
- **AWS CLI**: Cloud resource management
- **Git**: Version control
- **SSH Keys**: For secure server access

### AWS Configuration
1. Configure AWS CLI with appropriate credentials
2. Ensure proper IAM permissions for:
   - EC2 instance management
   - VPC and networking
   - Route53 DNS management
   - Security groups

## Infrastructure Deployment

### 1. Network Infrastructure

#### VPC and Networking
```bash
cd terraform/environments/netbird-vm
terraform init
terraform plan -var-file=variables.tfvars
terraform apply -var-file=variables.tfvars
```

**Components Created:**
- VPC with 10.0.0.0/16 CIDR
- Public subnets in us-east-1a
- Internet Gateway
- Route tables and associations
- Security groups

### 2. EC2 Instance

#### NetBird VPN Server
The NetBird instance provides:
- VPN connectivity for the homelab
- Reverse proxy (Caddy)
- Identity management (Zitadel)
- Management dashboard

**Instance Specifications:**
- Type: t3.small
- OS: Amazon Linux 2
- Storage: 60GB GP3
- Key pair: Use your SSH key name

## Service Deployment

### 1. NetBird VPN Stack

#### Prerequisites
- Domain name configured in Route53
- SSL certificates (managed by Caddy)
- Environment variables configured

#### Deployment Steps
```bash
# Navigate to service directory
cd services/netbird

# Copy and configure environment files
cp .env.example .env
# Edit .env with your configuration

# Start services
docker-compose up -d

# Verify services
docker-compose ps
docker-compose logs -f
```

#### Service Components
- **Caddy**: Reverse proxy and SSL termination
- **NetBird Management**: VPN management API
- **Zitadel**: Identity provider
- **PostgreSQL**: Database for Zitadel
- **Signal & Relay**: NetBird communication services

### 2. Reverse Proxy Setup

#### Traefik Configuration
```bash
cd services/traefik
cp .env.example .env
# Configure domain and SSL settings
docker-compose up -d
```

#### Nginx Proxy Manager
```bash
cd services/nginx-proxy-manager
docker-compose up -d
```

### 3. Application Services

#### NextCloud
```bash
cd services/nextcloud
cp .env.example .env
# Configure database and admin credentials
docker-compose up -d
```

#### Airflow
```bash
cd services/airflow
# Initialize database
docker-compose up airflow-init
# Start services
docker-compose up -d
```

#### Monitoring Stack
```bash
cd services/monitoring
docker-compose up -d
```

## Configuration

### Environment Variables

Create `.env` files from templates:
```bash
# For each service
cp .env.example .env
```

**Required Variables:**
- Domain names
- Database credentials
- API keys
- SSL certificate paths
- Service-specific configurations

### Network Configuration

#### Security Groups
- SSH access (port 22)
- HTTP/HTTPS (ports 80/443)
- NetBird VPN ports (3478, 10000, 33073, 33080)
- Custom application ports

#### DNS Configuration
- Route53 hosted zone setup
- A records for services
- CNAME records as needed

## Verification

### Service Health Checks

```bash
# Check container status
docker ps
docker-compose ps

# Check service logs
docker-compose logs [service-name]

# Verify network connectivity
curl -I https://your-domain.com
```

### Monitoring Setup

1. Access Prometheus: `http://monitoring.your-domain.com:9090`
2. Access Grafana: `http://monitoring.your-domain.com:3000`
3. Set up dashboards for:
   - Container resource usage
   - Network traffic
   - Application metrics

## Backup and Recovery

### Automated Backups
```bash
# Run backup script
./scripts/backup/backup-netbird.sh

# Schedule regular backups (crontab)
0 2 * * * /path/to/backup-netbird.sh
```

### Manual Backups
1. Database dumps
2. Configuration file backups
3. Docker volume backups
4. Terraform state backups

## Troubleshooting

### Common Issues

#### Network Connectivity
```bash
# Check security groups
aws ec2 describe-security-groups --group-ids sg-xxxxx

# Verify route tables
aws ec2 describe-route-tables --route-table-ids rtb-xxxxx
```

#### Container Issues
```bash
# Check container logs
docker-compose logs [service]

# Restart services
docker-compose restart [service]

# Rebuild containers
docker-compose up -d --build
```

#### DNS Issues
```bash
# Verify DNS records
nslookup your-domain.com

# Check Route53
aws route53 list-resource-record-sets --hosted-zone-id ZXXXXXXX
```

### Log Locations

- **Application logs**: `/var/log/containers/`
- **System logs**: `/var/log/`
- **Docker logs**: `docker-compose logs`
- **Terraform logs**: `terraform plan/apply` output

## Maintenance

### Regular Tasks

#### Weekly
- Update container images
- Review security groups
- Check backup integrity
- Monitor resource usage

#### Monthly
- Rotate SSL certificates
- Update system packages
- Review access logs
- Test recovery procedures

#### Quarterly
- Security audit
- Architecture review
- Performance optimization
- Documentation updates

## Scaling

### Horizontal Scaling
- Add more EC2 instances
- Configure load balancers
- Implement auto-scaling groups

### Vertical Scaling
- Upgrade instance types
- Increase storage capacity
- Optimize resource allocation

## Cost Optimization

### Monitoring Costs
- Use AWS Cost Explorer
- Set up billing alerts
- Monitor resource utilization
- Clean up unused resources

### Optimization Strategies
- Use spot instances for non-critical workloads
- Implement auto-scaling
- Use reserved instances for predictable workloads
- Monitor and right-size instances

## Security Hardening

### Network Security
- Implement network ACLs
- Use security groups with least privilege
- Enable VPC flow logs
- Use private subnets for internal services

### Application Security
- Regular vulnerability scanning
- Container image signing
- Secret management
- Regular patching

This deployment guide provides a comprehensive approach to setting up and maintaining your homelab infrastructure. Always test changes in a non-production environment first and maintain regular backups.
