# KawaiiSec OS Firewall Documentation

## Overview

KawaiiSec OS implements a robust, automated firewall protection system using UFW (Uncomplicated Firewall) to provide secure defaults while maintaining functionality for cybersecurity education and lab environments.

## Default Security Posture

### Core Security Principles

- **Deny by Default**: All incoming connections are blocked unless explicitly allowed
- **Allow Outbound**: Outbound connections are permitted to maintain system functionality
- **Minimal Attack Surface**: Only essential services and lab ports are exposed
- **Defense in Depth**: Multiple layers of security including rate limiting and network segmentation

### Default Policies

```bash
# Incoming: DENY (default)
# Outgoing: ALLOW (default)  
# Routed: ALLOW (for container networking)
```

## Open Ports and Services

### Essential Services

| Port | Protocol | Service | Purpose |
|------|----------|---------|---------|
| 22 | TCP | SSH | Remote system administration |
| 2222 | TCP | SSH Alt | Alternative SSH for lab containers |

### Web Services

| Port | Protocol | Service | Purpose |
|------|----------|---------|---------|
| 80 | TCP | HTTP | Web applications and lab exercises |
| 443 | TCP | HTTPS | Secure web applications |

### Vulnerable Web Applications

| Port | Protocol | Service | Purpose |
|------|----------|---------|---------|
| 8080 | TCP | DVWA | Damn Vulnerable Web Application |
| 3000 | TCP | Juice Shop | OWASP Juice Shop |
| 8081 | TCP | Apache Vuln | Vulnerable Apache server |

### Database Services

| Port | Protocol | Service | Purpose |
|------|----------|---------|---------|
| 3306 | TCP | MySQL | MySQL database for lab exercises |
| 5432 | TCP | PostgreSQL | PostgreSQL database for lab exercises |

### ELK Stack (Logging and Analysis)

| Port | Protocol | Service | Purpose |
|------|----------|---------|---------|
| 9200 | TCP | Elasticsearch | Search and analytics engine API |
| 9300 | TCP | Elasticsearch | Cluster communication |
| 5601 | TCP | Kibana | Data visualization web interface |
| 5044 | TCP | Logstash | Log ingestion from Beats |
| 9600 | TCP | Logstash | Monitoring API |

### File Transfer Services

| Port | Protocol | Service | Purpose |
|------|----------|---------|---------|
| 21 | TCP | FTP | FTP control channel |
| 30000-30009 | TCP | FTP Passive | FTP data transfer ports |

### Metasploitable Services

| Port | Protocol | Service | Purpose |
|------|----------|---------|---------|
| 2223 | TCP | SSH | Metasploitable SSH (vulnerable) |
| 2380 | TCP | HTTP | Metasploitable web server |
| 2443 | TCP | HTTPS | Metasploitable secure web |
| 2321 | TCP | FTP | Metasploitable FTP service |
| 2325 | TCP | SMTP | Metasploitable email server |
| 2353 | TCP | DNS | Metasploitable DNS server |
| 2389 | TCP | LDAP | Metasploitable directory service |

### Docker Networks

| Network | Purpose |
|---------|---------|
| 172.17.0.0/16 | Docker default bridge network |
| 172.20.0.0/16 | KawaiiSec lab network |

## Firewall Management

### Basic Commands

```bash
# Check firewall status
sudo kawaiisec-firewall-setup.sh status

# Reconfigure firewall (idempotent)
sudo kawaiisec-firewall-setup.sh setup

# Reset and reconfigure firewall
sudo kawaiisec-firewall-setup.sh reset

# Test firewall configuration
sudo kawaiisec-firewall-setup.sh test

# View detailed UFW status
sudo ufw status verbose

# View firewall logs
sudo tail -f /var/log/kawaiisec-firewall.log
```

### Configuration Files

- **Main Script**: `/usr/local/bin/kawaiisec-firewall-setup.sh`
- **Port Configuration**: `/etc/kawaiisec/lab_ports.conf`
- **Log File**: `/var/log/kawaiisec-firewall.log`
- **Backup Directory**: `/etc/kawaiisec/ufw-backup/`

## Customizing for Additional Labs

### Adding New Ports

1. **Edit the configuration file**:
   ```bash
   sudo nano /etc/kawaiisec/lab_ports.conf
   ```

2. **Add your port using the format**:
   ```
   PORT/PROTOCOL:SERVICE_NAME:DESCRIPTION:CATEGORY
   ```

3. **Reconfigure the firewall**:
   ```bash
   sudo kawaiisec-firewall-setup.sh reset
   ```

### Manual Port Management

```bash
# Allow a specific port
sudo ufw allow 8443/tcp comment 'Custom lab service'

# Allow from specific IP/network
sudo ufw allow from 192.168.1.0/24 to any port 22

# Delete a rule
sudo ufw delete allow 8443/tcp

# Rate limit a service (useful for SSH)
sudo ufw limit ssh
```

### Example: Adding a Custom Web Service

```bash
# Allow custom web service on port 8888
sudo ufw allow 8888/tcp comment 'Custom web lab'

# Verify the rule was added
sudo ufw status | grep 8888
```

## Network Security Features

### Rate Limiting

SSH connections are automatically rate-limited to prevent brute force attacks:
```bash
# Maximum 6 connections per 30-second window
sudo ufw limit ssh
```

### Docker Integration

The firewall is configured to work seamlessly with Docker:
- Container-to-container communication is allowed within lab networks
- Host-to-container communication is properly configured
- Docker bridge interfaces are handled automatically

### Logging

All firewall activities are logged to `/var/log/kawaiisec-firewall.log`:
```bash
# View recent firewall activity
sudo tail -f /var/log/kawaiisec-firewall.log

# View UFW logs
sudo journalctl -f -u ufw
```

## Troubleshooting

### Common Issues

#### 1. Service Cannot Connect

**Symptoms**: Lab services fail to start or are inaccessible

**Solution**:
```bash
# Check if port is allowed
sudo ufw status | grep PORT_NUMBER

# Check if service is running
sudo systemctl status SERVICE_NAME

# Check if port is actually in use
sudo ss -tulpn | grep PORT_NUMBER
```

#### 2. Docker Containers Cannot Communicate

**Symptoms**: Container networking issues, services cannot reach databases

**Solution**:
```bash
# Check Docker networks are allowed
sudo ufw status | grep 172.

# Ensure Docker daemon is running
sudo systemctl status docker

# Restart Docker if needed
sudo systemctl restart docker
```

#### 3. UFW Not Starting at Boot

**Symptoms**: Firewall is disabled after reboot

**Solution**:
```bash
# Check if UFW service is enabled
sudo systemctl status ufw

# Enable UFW service
sudo systemctl enable ufw

# Check KawaiiSec firewall service
sudo systemctl status kawaiisec-firewall.service
```

#### 4. Cannot Access Lab from Remote Machine

**Symptoms**: Lab services work locally but not from other machines

**Solution**:
```bash
# Check if UFW is allowing the connection
sudo ufw status verbose

# Ensure the service binds to all interfaces (0.0.0.0)
# Check Docker port mapping
docker ps

# Allow specific remote IP
sudo ufw allow from REMOTE_IP to any port PORT_NUMBER
```

### Diagnostic Commands

```bash
# Test network connectivity
nc -zv localhost PORT_NUMBER

# Check what's listening on ports
sudo ss -tulpn

# View UFW logs
sudo tail -f /var/log/ufw.log

# Check iptables rules (advanced)
sudo iptables -L -n -v

# Test firewall rules
sudo ufw --dry-run allow 8888/tcp
```

### Performance Monitoring

```bash
# Monitor connection attempts
sudo journalctl -f -u ufw | grep BLOCK

# Check system resource usage
htop

# Monitor Docker resource usage
docker stats

# Check firewall rule efficiency
sudo iptables -L -n -v --line-numbers
```

## Security Best Practices

### Regular Maintenance

1. **Review firewall logs weekly**:
   ```bash
   sudo grep BLOCK /var/log/ufw.log | tail -20
   ```

2. **Update firewall rules when adding new labs**:
   ```bash
   sudo kawaiisec-firewall-setup.sh reset
   ```

3. **Backup firewall configuration before changes**:
   ```bash
   sudo cp -r /etc/ufw /home/backup/ufw-$(date +%Y%m%d)
   ```

### Network Segmentation

For production environments, consider:
- Using VLANs to separate lab traffic
- Implementing VPN access for remote users
- Creating dedicated network segments for different lab types

### Access Control

1. **Use strong SSH keys instead of passwords**
2. **Limit SSH access to specific IP addresses**
3. **Regularly rotate lab environment credentials**
4. **Monitor for unusual network activity**

### Compliance Considerations

The firewall configuration follows security best practices and can help with:
- **CIS Controls**: Implements boundary defense controls
- **NIST Framework**: Supports Protect (PR) function
- **Educational Standards**: Provides safe learning environment

## Integration with CI/CD

The firewall setup includes automated testing that can be integrated into build pipelines:

```bash
# Test firewall in CI/CD
make test-firewall

# Check specific ports are open
sudo kawaiisec-firewall-setup.sh test
```

## Advanced Configuration

### Custom UFW Application Profiles

Create custom application profiles in `/etc/ufw/applications.d/`:

```ini
[KawaiiSec-Custom]
title=Custom KawaiiSec Service
description=Custom service for KawaiiSec labs
ports=8888/tcp
```

### Integration with Other Security Tools

The firewall works alongside other security tools:
- OSSEC/HIDS for intrusion detection
- Fail2ban for automated IP blocking
- Snort/Suricata for network monitoring

### Nftables Fallback

For advanced users requiring nftables:
```bash
# Install nftables
sudo apt install nftables

# Basic nftables configuration for KawaiiSec
sudo nft add table inet filter
sudo nft add chain inet filter input { type filter hook input priority 0; policy drop; }
sudo nft add rule inet filter input ct state established,related accept
sudo nft add rule inet filter input iif lo accept
sudo nft add rule inet filter input tcp dport 22 accept
```

## Getting Help

- **Documentation**: This file and `/usr/share/doc/kawaiisec-tools/`
- **Logs**: `/var/log/kawaiisec-firewall.log`
- **Community**: KawaiiSec OS GitHub repository
- **Testing**: Use `kawaiisec-firewall-setup.sh test` for diagnosis

For additional support, check the system status and logs, then consult the KawaiiSec OS documentation or community resources. 