# Tabiri Homelab Architecture

## Overview

This homelab implements a modular, containerized infrastructure for learning and experimenting with cloud technologies, networking, and automation.

## System Architecture

### Network Topology
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Public Cloud  │    │   VPN Gateway   │    │  Local Network  │
│   (AWS/Azure)   │◄──►│   (NetBird)     │◄──►│   (Proxmox)     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Cloud Services │    │  Management     │    │  Local Services │
│  • Airflow      │    │  • Traefik      │    │  • NextCloud    │
│  • Monitoring   │    │  • Portainer    │    │  • JDownload    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Core Components

#### 1. Infrastructure Layer
- **Proxmox**: Virtualization platform for local VMs and containers
- **AWS EC2**: Cloud instances for external-facing services
- **NetBird VPN**: Zero-trust networking between cloud and local resources

#### 2. Container Orchestration
- **Docker**: Container runtime for all services
- **Docker Compose**: Service definition and orchestration
- **Portainer**: Container management UI

#### 3. Networking & Security
- **Traefik**: Reverse proxy with automatic SSL
- **Nginx Proxy Manager**: Web-based proxy management
- **NetBird**: Mesh VPN and zero-trust access
- **Security Groups**: Network segmentation and firewall rules

#### 4. Monitoring & Observability
- **Prometheus**: Metrics collection and storage
- **Grafana**: Dashboards and visualization
- **Custom Scripts**: Health checks and alerting

#### 5. Automation & CI/CD
- **Terraform**: Infrastructure as Code
- **Ansible**: Configuration management
- **Semaphore**: Ansible automation platform
- **Airflow**: Workflow orchestration

## Service Dependencies

### Critical Path Services
1. **NetBird VPN** (Foundation)
   - Provides secure connectivity between all components
   - Must be running before other cross-network services

2. **Traefik/Proxy** (Routing)
   - Handles SSL termination and routing
   - Required for web-accessible services

3. **Monitoring** (Observability)
   - Provides visibility into system health
   - Should be deployed early for monitoring other services

### Independent Services
- NextCloud (file sharing)
- JDownload (download manager)
- Portainer (container management)

## Data Flow

### User Access Flow
```
User Request → CloudFlare/ISP → Traefik Proxy → Service Container → Database
```

### Backup Flow
```
Service Data → Backup Script → Compressed Archive → Cloud Storage/Local Backup
```

### Monitoring Flow
```
Service Metrics → Prometheus → Grafana Dashboard → Alert Manager → Notification
```

## Security Architecture

### Network Segmentation
- **Public Zone**: Internet-facing services (ports 80/443)
- **DMZ Zone**: Proxy and gateway services
- **Private Zone**: Internal services requiring VPN access
- **Management Zone**: Administrative interfaces

### Access Control
- **SSH Keys**: Primary authentication method
- **VPN Access**: Required for internal services
- **Role-Based Access**: Different permission levels per service

## Scaling Considerations

### Horizontal Scaling
- Stateless services can be scaled horizontally
- Load balancing through Traefik
- Database connections managed per service

### Vertical Scaling
- Resource-intensive services on dedicated hosts
- GPU-accelerated services on appropriate hardware
- Memory-intensive services with adequate RAM allocation

## Backup Strategy

### Tier 1 (Critical)
- Configuration files (version controlled)
- Database dumps (automated daily)
- Service state (scheduled backups)

### Tier 2 (Important)
- Application data (scheduled backups)
- Log files (rotated and archived)
- Monitoring data (retention policies)

### Tier 3 (Optional)
- Temporary files
- Cache data
- Build artifacts

## High Availability

### Current State
- Single instance deployment for most services
- Manual failover procedures
- Regular backups for disaster recovery

### Future Enhancements
- Multi-node clustering for critical services
- Automated failover
- Geographic redundancy

## Technology Stack

### Infrastructure
- **Virtualization**: Proxmox, LXC Containers
- **Cloud**: AWS EC2, Route53
- **Networking**: Docker Networking, VPN, Security Groups

### Containerization
- **Runtime**: Docker
- **Orchestration**: Docker Compose
- **Management**: Portainer

### Monitoring & Logging
- **Metrics**: Prometheus
- **Visualization**: Grafana
- **Logging**: JSON-file driver with rotation

### Automation
- **IaC**: Terraform
- **Config Management**: Ansible
- **Workflows**: Airflow
- **CI/CD**: Semaphore

This architecture provides a flexible foundation for learning and experimentation while maintaining security and operational best practices.
