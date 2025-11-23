# Tabiri Homelab

A comprehensive home lab infrastructure for experimenting with cloud technologies, containerization, and automation.

## 🏗️ Project Structure

```
tabiri-homelab/
├── README.md                          # This file
├── .gitignore                         # Git ignore rules
├── .env.example                       # Environment variables template
├── docs/                              # Documentation
│   ├── architecture.md               # System architecture
│   ├── deployment-guide.md           # Deployment instructions
│   └── security.md                   # Security guidelines
├── terraform/                         # Infrastructure as Code
│   ├── modules/                      # Reusable Terraform modules
│   ├── environments/                 # Environment-specific configs
│   └── backend.tf.example            # Backend configuration template
├── services/                          # Service deployments
│   ├── traefik/                      # Reverse proxy
│   ├── monitoring/                   # Monitoring stack
│   ├── nextcloud/                    # File sharing
│   └── ...                           # Other services
├── scripts/                          # Utility scripts
│   ├── backup/                       # Backup scripts
│   ├── deployment/                   # Deployment scripts
│   └── monitoring/                   # Monitoring scripts
└── config/                           # Configuration files
    ├── templates/                    # Configuration templates
    └── examples/                     # Example configurations
```

## 🚀 Quick Start

### Prerequisites
- Docker & Docker Compose
- Terraform (for infrastructure provisioning)
- AWS CLI (for cloud resources)
- Git

### Initial Setup
1. Clone this repository
2. Copy `.env.example` to `.env` and configure your environment variables
3. Review and customize configuration files in `config/templates/`
4. Follow deployment guides in `docs/`

## 📋 Services Overview

### Infrastructure
- **NetBird VPN**: Self-hosted VPN and zero-trust networking
- **Traefik**: Reverse proxy and load balancer
- **Nginx Proxy Manager**: Web-based proxy management
- **Portainer**: Container management UI

### Applications
- **NextCloud**: Self-hosted file sharing and collaboration
- **Airflow**: Workflow orchestration
- **Semaphore**: Ansible automation platform
- **Monitoring Stack**: Prometheus, Grafana, and alerting

### Management
- **Proxmox**: Virtualization management
- **Ansible**: Configuration management
- **Terraform**: Infrastructure provisioning

## 🔧 Usage

### Infrastructure Deployment
```bash
# Deploy with Terraform
cd terraform/environments/dev
terraform init
terraform plan
terraform apply
```

### Service Management
```bash
# Start a specific service
cd services/traefik
docker-compose up -d

# View logs
docker-compose logs -f
```

### Backup & Restore
```bash
# Run backup scripts
./scripts/backup/backup-all.sh

# Restore from backup
./scripts/backup/restore-backup.sh <backup-file>
```

## 🔒 Security

- All sensitive data should be stored in environment variables
- Use `.env` files for local development (added to `.gitignore`)
- Regular security updates and monitoring
- Network segmentation and firewall rules

## 📚 Documentation

- [Architecture Overview](docs/architecture.md)
- [Deployment Guide](docs/deployment-guide.md)
- [Security Guidelines](docs/security.md)
- [Backup Procedures](docs/backup-procedures.md)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is for educational and personal use.

## ⚠️ Important Notes

- This is a homelab environment - not for production use
- Always backup your data before making changes
- Monitor resource usage and costs for cloud services
- Keep software updated for security patches
