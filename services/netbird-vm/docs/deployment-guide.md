# NetBird VM Deployment Guide

This guide provides step-by-step instructions for deploying the NetBird VPN solution using the provided Terraform and Docker Compose configurations.

## Prerequisites

Before beginning the deployment, ensure you have the following:

1. AWS account with appropriate permissions
2. AWS CLI configured with credentials
3. Terraform (v1.5+) installed
4. Docker and Docker Compose installed
5. SSH key pair (for EC2 access)

## Step 1: Configure AWS Credentials

Configure your AWS CLI with credentials that have permissions to create EC2 instances, VPCs, security groups, and Route53 records:

```bash
aws configure
```

## Step 2: Review Terraform Configuration

Before deploying, review the following files:
- `main.tf`: Main infrastructure configuration
- `sg.tf`: Security group rules
- `vpc.tf`: VPC and networking configuration

Update any placeholder values:
- SSH key name
- Route53 hosted zone ID
- Domain name

## Step 3: Initialize Terraform

Initialize the Terraform working directory:

```bash
terraform init
```

## Step 4: Plan the Deployment

Review what will be created:

```bash
terraform plan
```

## Step 5: Apply the Configuration

Deploy the infrastructure:

```bash
terraform apply
```

Confirm by typing `yes` when prompted.

## Step 6: Access the Instance

Once the deployment is complete, note the public IP address of the instance from the Terraform output or AWS console.

Connect via SSH using your key pair:

```bash
ssh -i /path/to/your/key.pem ec2-user@PUBLIC_IP
```

## Step 7: Deploy NetBird Services

Copy the `docker-compose.yml` file to the EC2 instance and run:

```bash
docker-compose up -d
```

## Step 8: Configure DNS

The Terraform configuration creates a Route53 record pointing to the instance. Ensure your domain's DNS settings are correctly configured to use the Route53 hosted zone.

## Verification

After deployment, you should be able to access:
- NetBird Management UI: `https://your-domain`
- NetBird Dashboard: `https://your-domain:8080`

## Post-Deployment Configuration

1. Access the NetBird management interface and configure your identity provider
2. Set up users and groups
3. Configure additional security settings as needed

## Troubleshooting

If you encounter issues:

1. Check Docker service status:
   ```bash
   docker-compose ps
   ```

2. View service logs:
   ```bash
   docker-compose logs [service-name]
   ```

3. Verify all required ports are accessible through security groups

## Next Steps

After successful deployment, review and implement the security guidelines in [security.md](security.md).
