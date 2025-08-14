#!/bin/bash

# Redis Sentinel Cluster Setup Script
# This script provides a quick way to deploy the Redis Sentinel cluster

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== Redis Sentinel Cluster Setup ==="
echo

# Check if ansible is installed
if ! command -v ansible-playbook &> /dev/null; then
    echo "ERROR: Ansible is not installed. Please install Ansible first."
    echo "Install with: pip install ansible"
    exit 1
fi

# Check if inventory exists
if [ ! -f "$PROJECT_DIR/inventory/hosts" ]; then
    echo "WARNING: inventory/hosts not found. Copying from example..."
    cp "$PROJECT_DIR/inventory/hosts.example" "$PROJECT_DIR/inventory/hosts"
    echo "Please edit inventory/hosts with your server details before running the playbook."
    echo "File location: $PROJECT_DIR/inventory/hosts"
    exit 1
fi

echo "Configuration files found. Starting deployment..."
echo

# Function to run playbook with error handling
run_playbook() {
    local playbook=$1
    local description=$2
    
    echo "=== $description ==="
    if ansible-playbook -i "$PROJECT_DIR/inventory/hosts" "$PROJECT_DIR/$playbook"; then
        echo "✓ $description completed successfully"
    else
        echo "✗ $description failed"
        exit 1
    fi
    echo
}

# Parse command line arguments
case "${1:-deploy}" in
    "check-versions")
        run_playbook "check-redis-versions.yml" "Checking available Redis versions"
        ;;
    "deploy")
        run_playbook "site.yml" "Deploying Redis Sentinel Cluster"
        ;;
    "test")
        run_playbook "test-cluster.yml" "Testing Redis Sentinel Cluster"
        ;;
    "failover-test")
        echo "WARNING: This will trigger a failover test which may affect your cluster."
        read -p "Are you sure you want to proceed? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ansible-playbook -i "$PROJECT_DIR/inventory/hosts" "$PROJECT_DIR/failover-test.yml" --tags failover
        else
            echo "Failover test cancelled."
        fi
        ;;
    "status")
        echo "=== Checking Cluster Status ==="
        if [ -f "$PROJECT_DIR/inventory/hosts" ]; then
            # Extract host IPs from inventory
            hosts=$(grep ansible_host "$PROJECT_DIR/inventory/hosts" | awk '{print $2}' | cut -d= -f2 | tr '\n' ' ')
            "$PROJECT_DIR/scripts/check-cluster-status.sh" $hosts
        else
            echo "No inventory file found. Using localhost..."
            "$PROJECT_DIR/scripts/check-cluster-status.sh"
        fi
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [command]"
        echo
        echo "Commands:"
        echo "  deploy         - Deploy Redis Sentinel cluster (default)"
        echo "  check-versions - Check available Redis versions"
        echo "  test          - Test the deployed cluster"
        echo "  failover-test - Run failover test (destructive)"
        echo "  status        - Check cluster status"
        echo "  help          - Show this help message"
        echo
        echo "Examples:"
        echo "  $0                    # Deploy cluster"
        echo "  $0 check-versions     # Check Redis versions"
        echo "  $0 test              # Test cluster"
        echo "  $0 status            # Check status"
        ;;
    *)
        echo "Unknown command: $1"
        echo "Use '$0 help' for usage information."
        exit 1
        ;;
esac

echo "=== Operation completed ==="
