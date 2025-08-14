#!/bin/bash

# Redis Sentinel Cluster Status Script
# This script checks the status of Redis and Sentinel services

set -e

REDIS_PORT=${REDIS_PORT:-6379}
SENTINEL_PORT=${SENTINEL_PORT:-26379}
MASTER_NAME=${MASTER_NAME:-mymaster}

echo "=== Redis Sentinel Cluster Status ==="
echo

# Check if redis-cli is available
if ! command -v redis-cli &> /dev/null; then
    echo "ERROR: redis-cli not found. Please install Redis client tools."
    exit 1
fi

# Function to check service status
check_service_status() {
    local service=$1
    local port=$2
    local host=${3:-localhost}
    
    echo "Checking $service on $host:$port..."
    
    if redis-cli -h $host -p $port ping >/dev/null 2>&1; then
        echo "✓ $service is running on $host:$port"
        return 0
    else
        echo "✗ $service is not responding on $host:$port"
        return 1
    fi
}

# Function to get master info from sentinel
get_master_info() {
    local sentinel_host=${1:-localhost}
    echo "Getting master info from Sentinel on $sentinel_host:$SENTINEL_PORT..."
    
    master_info=$(redis-cli -h $sentinel_host -p $SENTINEL_PORT sentinel get-master-addr-by-name $MASTER_NAME 2>/dev/null || echo "ERROR")
    
    if [ "$master_info" != "ERROR" ]; then
        master_ip=$(echo "$master_info" | head -n1)
        master_port=$(echo "$master_info" | tail -n1)
        echo "✓ Current master: $master_ip:$master_port"
        echo "$master_ip:$master_port"
    else
        echo "✗ Could not get master info from Sentinel"
        return 1
    fi
}

# Function to get replication info
get_replication_info() {
    local redis_host=$1
    local redis_port=${2:-$REDIS_PORT}
    
    echo "Getting replication info from Redis on $redis_host:$redis_port..."
    
    repl_info=$(redis-cli -h $redis_host -p $redis_port info replication 2>/dev/null || echo "ERROR")
    
    if [ "$repl_info" != "ERROR" ]; then
        echo "Replication info:"
        echo "$repl_info" | grep -E "(role:|master_host:|master_port:|connected_slaves:)"
    else
        echo "✗ Could not get replication info"
        return 1
    fi
}

# Function to list sentinel slaves
get_sentinel_slaves() {
    local sentinel_host=${1:-localhost}
    echo "Getting slaves info from Sentinel on $sentinel_host:$SENTINEL_PORT..."
    
    slaves_info=$(redis-cli -h $sentinel_host -p $SENTINEL_PORT sentinel slaves $MASTER_NAME 2>/dev/null || echo "ERROR")
    
    if [ "$slaves_info" != "ERROR" ]; then
        echo "Slaves registered with Sentinel:"
        echo "$slaves_info" | grep -E "(ip|port|flags)" || echo "No slaves found"
    else
        echo "✗ Could not get slaves info from Sentinel"
        return 1
    fi
}

# Main execution
main() {
    local hosts=("$@")
    
    # If no hosts provided, use localhost
    if [ ${#hosts[@]} -eq 0 ]; then
        hosts=("localhost")
    fi
    
    echo "Checking Redis Sentinel cluster on hosts: ${hosts[*]}"
    echo
    
    # Check Redis and Sentinel services on each host
    for host in "${hosts[@]}"; do
        echo "=== Checking host: $host ==="
        check_service_status "Redis" $REDIS_PORT $host
        check_service_status "Sentinel" $SENTINEL_PORT $host
        echo
    done
    
    # Get master info from first available sentinel
    echo "=== Master Information ==="
    for host in "${hosts[@]}"; do
        if master_addr=$(get_master_info $host); then
            break
        fi
    done
    echo
    
    # Get replication info from master if found
    if [ -n "$master_addr" ]; then
        echo "=== Replication Information ==="
        master_ip=$(echo "$master_addr" | cut -d: -f1)
        master_port=$(echo "$master_addr" | cut -d: -f2)
        get_replication_info $master_ip $master_port
        echo
    fi
    
    # Get slaves info from sentinel
    echo "=== Slaves Information ==="
    for host in "${hosts[@]}"; do
        if get_sentinel_slaves $host; then
            break
        fi
    done
    echo
    
    echo "=== Cluster Health Summary ==="
    echo "✓ Cluster status check completed"
}

# Script usage
usage() {
    echo "Usage: $0 [host1] [host2] [host3] ..."
    echo "Example: $0 10.0.1.10 10.0.1.11 10.0.1.12"
    echo
    echo "Environment variables:"
    echo "  REDIS_PORT    - Redis port (default: 6379)"
    echo "  SENTINEL_PORT - Sentinel port (default: 26379)"
    echo "  MASTER_NAME   - Master name (default: mymaster)"
}

# Check for help flag
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
    exit 0
fi

# Run main function with all arguments
main "$@"
