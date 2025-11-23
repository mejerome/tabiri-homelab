# NetBird VM Security Guidelines

This document outlines security considerations and best practices for the NetBird VPN deployment.

## Current Security Issues

### 1. Overly Permissive Security Groups

The current security group configuration allows access from `0.0.0.0/0` for multiple ports:
- SSH (22/tcp)
- SMTP over TLS (587/tcp)
- Custom TCP (45876/tcp)
- HTTP (80/tcp)
- HTTPS (443/tcp)
- NetBird specific ports (10000/tcp, 33073/tcp, 33080/tcp)
- WireGuard ports (3478/udp, 49152-65535/udp)

**Recommendation:** Restrict access to specific IP ranges or use VPN access for management ports.

### 2. SSH Key Management

The configuration references a hardcoded SSH key name "syslog".

**Recommendation:** Use a more descriptive name and ensure proper key management.

### 3. Route53 Zone ID Exposure

The Route53 hosted zone ID is hardcoded in the Terraform configuration.

**Recommendation:** Use variables or secure parameter storage.

### 4. Missing Encryption

The root block device is not encrypted by default.

**Recommendation:** Enable encryption for all EBS volumes.

## Security Recommendations

### 1. Network Security

#### Restrict Security Group Access
Update `sg.tf` to limit access to specific IP ranges:
```hcl
ingress {
  description = "SSH"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["YOUR_ADMIN_IP/32"]  # Replace with your admin IP
}
```

#### Use a Bastion Host
Consider deploying a bastion host for secure access to the NetBird instance.

#### Enable VPC Flow Logs
Monitor network traffic for anomalies.

### 2. Instance Security

#### Enable EBS Encryption
Update `main.tf` to enable encryption:
```hcl
root_block_device {
  encrypted = true
}
```

#### Regular Security Updates
Implement a process for regular OS and software updates.

#### SSH Hardening
- Disable password authentication
- Use SSH key-based authentication only
- Change the default SSH port
- Implement fail2ban or similar intrusion prevention

### 3. Application Security

#### Secure Configuration Files
- Ensure proper permissions on `.env` files (600)
- Avoid storing secrets in plain text
- Use a secrets management solution (e.g., AWS Secrets Manager)

#### TLS Certificates
- Use valid TLS certificates for all services
- Implement proper certificate rotation
- Enable HSTS headers

#### Identity Provider Security
- Implement multi-factor authentication
- Regularly review user access
- Enable audit logging

### 4. Data Security

#### Backup Encryption
- Encrypt all backup files
- Store backups in secure, access-controlled locations
- Implement backup retention policies

#### Database Security
- Use strong passwords for database access
- Regularly update Zitadel and PostgreSQL
- Implement database activity monitoring

### 5. Monitoring and Logging

#### Enable CloudWatch Monitoring
- Monitor instance metrics
- Set up alerts for unusual activity
- Log security group changes

#### Application Logging
- Centralize Docker logs
- Implement log rotation
- Retain logs for compliance requirements

### 6. Access Control

#### Principle of Least Privilege
- Review and minimize IAM permissions
- Use role-based access control
- Implement temporary access for administrative tasks

#### Regular Access Reviews
- Periodically review SSH keys
- Remove unused user accounts
- Audit access logs

## Implementation Checklist

- [ ] Restrict security group access to specific IP ranges
- [ ] Enable EBS encryption for all volumes
- [ ] Implement SSH key rotation process
- [ ] Secure all configuration files with proper permissions
- [ ] Enable and configure TLS certificates
- [ ] Implement multi-factor authentication
- [ ] Set up monitoring and alerting
- [ ] Establish backup encryption and retention policies
- [ ] Review and minimize IAM permissions
- [ ] Implement regular security update process

## Incident Response

In case of a security incident:
1. Isolate the affected systems
2. Preserve evidence (logs, snapshots)
3. Assess the scope of the breach
4. Implement remediation measures
5. Document the incident and lessons learned
6. Review and update security measures
