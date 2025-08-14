# Redis Sentinel Cluster with Ansible

This Ansible playbook sets up a three-node Redis Sentinel cluster on Ubuntu servers for high availability using the official Redis APT repository.

## Architecture

- 3 Redis instances (1 master, 2 slaves)
- 3 Sentinel instances (one on each server)
- Automatic failover capability
- Uses official Redis APT packages

## Prerequisites

- 3 Ubuntu servers (18.04 or later)
- SSH access to all servers
- Python 3 installed on target servers
- Ansible installed on control machine

## Quick Start

1. Update the inventory file with your server IPs:
   ```bash
   cp inventory/hosts.example inventory/hosts
   # Edit inventory/hosts with your server details
   ```

2. Configure variables in `group_vars/all.yml` if needed

3. (Optional) Check available Redis versions:
   ```bash
   ansible-playbook -i inventory/hosts check-redis-versions.yml
   ```

4. Run the playbook:
   ```bash
   ansible-playbook -i inventory/hosts site.yml
   ```

## Configuration

- Redis configuration: `templates/redis.conf.j2`
- Sentinel configuration: `templates/sentinel.conf.j2`
- Variables: `group_vars/all.yml`

### Redis Version

By default, the latest available Redis version will be installed. To install a specific version:

1. Check available versions: `ansible-playbook -i inventory/hosts check-redis-versions.yml`
2. Set `redis_version` in `group_vars/all.yml` (e.g., `redis_version: "6:7.4.2-1rl1~jammy1"`)

## Installation Method

This playbook follows the official Redis documentation for APT installation:
- Adds the official Redis APT repository
- Installs Redis using APT package manager
- Supports version specification
- Uses systemd for service management

## Testing

After deployment, you can test the cluster:

```bash
# Connect to Redis master
redis-cli -h <master-ip> -p 6379

# Check sentinel status
redis-cli -h <any-server-ip> -p 26379 sentinel masters
```

## Security Notes

- Consider setting up firewall rules
- Use Redis AUTH for production
- Configure SSL/TLS if needed
