#!/bin/bash

# Function to check if Docker Desktop is running
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        echo "Docker Desktop is not running. Please start Docker Desktop and try again."
        exit 1
    fi
}

# Function to create a Kubernetes cluster with KIND and a specific name
create_cluster() {
    local cluster_name=$1
    echo "Creating a Kubernetes cluster named '$cluster_name' with KIND..."
    kind create cluster --name "$cluster_name" --config ~/dev-setup/kind/kind-config.yaml
}

# Function to destroy a Kubernetes cluster by its name
destroy_cluster() {
    local cluster_name=$1
    echo "Destroying the Kubernetes cluster named '$cluster_name'..."
    kind delete cluster --name "$cluster_name"
}

# Main script logic
if [[ $# -lt 2 ]]; then
    echo "Usage: $0 {create|destroy} <cluster-name>"
    exit 1
fi

case "$1" in
    create)
        check_docker
        create_cluster "$2"
        ;;
    destroy)
        destroy_cluster "$2"
        ;;
    *)
        echo "Usage: $0 {create|destroy} <cluster-name>"
        exit 1
        ;;
esac
