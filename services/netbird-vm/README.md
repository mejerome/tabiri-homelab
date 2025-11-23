# NetBird VM Self-Hosted Setup

This repository contains the infrastructure as code (IaC) and configuration files for deploying a self-hosted NetBird VPN solution on AWS.

## Overview

NetBird is an open-source zero-configuration VPN solution that allows you to create a secure network between your devices. This project provides Terraform configurations to deploy the required AWS infrastructure and Docker Compose files to run the NetBird services.

## Directory Structure

```
.
├── backup-restore/     # Backup and restore scripts
├── docs/               # Documentation
├── .terraform/         # Terraform files (generated)
├── .terraform.lock.hcl # Terraform provider lock file
├── docker-compose.yml  # Main Docker Compose configuration
├── main.tf             # Main Terraform configuration
├── sg.tf               # Security group configuration
├── terraform.tfstate   # Terraform state file
├── terraform.tfstate.backup # Terraform state backup
└── vpc.tf              # VPC configuration
```

## Documentation

- [Deployment Guide](docs/deployment-guide.md)
- [Backup Procedures](docs/backup-procedures.md)
- [Security Guidelines](docs/security.md)

## Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform (v1.5+)
- Docker and Docker Compose
- SSH key pair for EC2 access

## Quick Start

1. Configure your AWS credentials:
   ```bash
   aws configure
   ```

2. Initialize Terraform:
   ```bash
   terraform init
   ```

3. Review the infrastructure plan:
   ```bash
   terraform plan
   ```

4. Deploy the infrastructure:
   ```bash
   terraform apply
   ```

5. Deploy NetBird services:
   ```bash
   docker-compose up -d
   ```

## Security Considerations

Before deploying to production, please review the [Security Guidelines](docs/security.md) to ensure all configurations meet your security requirements.

## Contributing

Please read the documentation files before making changes to understand the proper procedures.
