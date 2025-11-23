# Nextcloud AIO with Nginx Proxy Manager

This setup runs Nextcloud AIO behind Nginx Proxy Manager for SSL termination and reverse proxy functionality.

## Architecture

```
Internet → Nginx Proxy Manager (Ports 80/443) → Nextcloud AIO Master Container (Port 11000)
```

## Prerequisites

1. Domain name pointing to your server IP (nextcloud.syslogsolution.us)
2. Docker and Docker Compose installed
3. Ports 80 and 443 available on your server

## Setup Instructions

### 1. Start Nginx Proxy Manager

```bash
cd /Users/jerome/Documents/local-repo/tabiri-homelab/nginx-proxy-manager
docker-compose up -d
```

### 2. Configure Nginx Proxy Manager

1. Access the admin interface at `http://your-server-ip:81`
2. Default login: `admin@example.com` / `changeme`
3. Change the default password immediately
4. Add SSL certificate for your domain (Let's Encrypt)

### 3. Configure Proxy Host in NPM

1. Go to **Hosts** → **Proxy Hosts** → **Add Proxy Host**
2. Configure as follows:

**Details Tab:**
- Domain Names: `nextcloud.syslogsolution.us`
- Forward Hostname/IP: `host.docker.internal` (or your server IP)
- Forward Port: `11000`
- Block Common Exploits: ✅ Enabled
- Websockets Support: ✅ Enabled

**SSL Tab:**
- SSL Certificate: Request a new SSL Certificate
- Force SSL: ✅ Enabled
- HTTP/2 Support: ✅ Enabled
- HSTS Enabled: ✅ Enabled
- HSTS Subdomains: ✅ Enabled

**Advanced Tab:**
```nginx
# Custom Nginx Configuration
client_max_body_size 10G;
proxy_buffering off;

# Security headers
add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
add_header X-Content-Type-Options nosniff always;
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "no-referrer-when-downgrade" always;

# Nextcloud AIO specific headers
proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
```

### 4. Start Nextcloud AIO

```bash
cd /Users/jerome/Documents/local-repo/tabiri-homelab/nextcloud-aio
docker-compose up -d
```

### 5. Complete Nextcloud AIO Setup

1. Access `https://nextcloud.syslogsolution.us`
2. Follow the AIO setup wizard
3. The domain validation should now pass successfully

## Troubleshooting

### Common Issues

1. **Domain Validation Failed**
   - Ensure NPM proxy host is correctly configured
   - Check that port 11000 is accessible internally
   - Verify SSL certificate is valid

2. **Connection Timeouts**
   - Check if Nextcloud AIO container is running: `docker ps`
   - Verify NPM can reach the backend: `curl http://localhost:11000`

3. **SSL Issues**
   - Ensure Let's Encrypt certificate is properly issued
   - Check domain DNS records point to correct IP

### Debug Commands

```bash
# Check container status
docker ps -a

# View Nextcloud AIO logs
docker logs nextcloud-aio-mastercontainer

# View NPM logs
docker logs nginx-proxy-manager

# Test backend connectivity
curl -v http://localhost:11000

# Check network connectivity
docker network ls
```

## Backup and Restore

Nextcloud AIO includes built-in backup functionality. Ensure the volume `nextcloud_aio_mastercontainer` is included in your backup strategy.

## Security Considerations

- Keep containers updated regularly
- Use strong passwords for NPM admin interface
- Enable 2FA where possible
- Regular security scanning of containers
- Monitor logs for suspicious activity

## Maintenance

### Updates
```bash
# Update Nextcloud AIO
cd nextcloud-aio
docker-compose pull
docker-compose up -d

# Update NPM
cd nginx-proxy-manager  
docker-compose pull
docker-compose up -d
```

### Logs Monitoring
```bash
# Follow Nextcloud AIO logs
docker logs -f nextcloud-aio-mastercontainer

# Follow NPM logs
docker logs -f nginx-proxy-manager
```

## File Structure

```
tabiri-homelab/
├── nextcloud-aio/
│   ├── docker-compose.yml
│   └── README.md
└── nginx-proxy-manager/
    ├── docker-compose.yml
    ├── data/ (created automatically)
    └── letsencrypt/ (created automatically)
```
