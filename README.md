# Redis Sentinel Cluster with Ansible

This Ansible playbook sets up a three-node Redis Sentinel cluster on Ubuntu servers for high availability.

## Architecture

- 3 Redis instances (1 master, 2 slaves)
- 3 Sentinel instances (one on each server)
- Automatic failover capability

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

3. Run the playbook:
   ```bash
   ansible-playbook -i inventory/hosts site.yml
   ```

## Configuration

- Redis configuration: `templates/redis.conf.j2`
- Sentinel configuration: `templates/sentinel.conf.j2`
- Variables: `group_vars/all.yml`

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
