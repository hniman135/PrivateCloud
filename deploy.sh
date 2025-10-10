#!/bin/bash
# Ansible Deployment Script for Private Cloud on OpenShift
# This script runs Ansible playbook in WSL environment
# Usage: wsl bash deploy.sh

set -e  # Exit on error

echo "=================================="
echo "Private Cloud Deployment Script"
echo "Using Ansible for Infrastructure Automation"
echo "=================================="
echo ""

# Check if ansible is installed
if ! command -v ansible-playbook &> /dev/null; then
    echo "❌ Ansible not found. Installing..."
    sudo apt update
    sudo apt install -y ansible
    echo "✓ Ansible installed successfully"
fi

# Check if oc CLI is installed
if ! command -v oc &> /dev/null; then
    echo "❌ OpenShift CLI not found. Installing..."
    
    # Install curl if not present
    if ! command -v curl &> /dev/null; then
        sudo apt update
        sudo apt install -y curl
    fi
    
    # Download and install oc CLI
    curl -LO https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-linux.tar.gz
    tar -xzf openshift-client-linux.tar.gz
    sudo mv oc /usr/local/bin/
    sudo chmod +x /usr/local/bin/oc
    rm -f openshift-client-linux.tar.gz kubectl
    echo "✓ OpenShift CLI installed successfully"
fi

# Verify OpenShift login
echo ""
echo "Checking OpenShift login status..."
if ! oc whoami &> /dev/null; then
    echo "❌ Not logged in to OpenShift"
    echo "Please run: oc login --token=<YOUR_TOKEN> --server=https://api.rm2.thpm.p1.openshiftapps.com:6443"
    exit 1
fi

OC_USER=$(oc whoami)
OC_PROJECT=$(oc project -q)
echo "✓ Logged in as: $OC_USER"
echo "✓ Current project: $OC_PROJECT"
echo ""

# Convert Windows path to WSL path
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
cd "$SCRIPT_DIR"

echo "Running Ansible playbook..."
echo "=================================="
echo ""

# Set locale to avoid warnings
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

# Run Ansible playbook with verbose output
ansible-playbook \
    -i ansible/inventory \
    ansible/playbook.yml \
    -v

echo ""
echo "=================================="
echo "✓ Deployment completed successfully!"
echo "=================================="
