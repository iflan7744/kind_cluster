#!/usr/bin/env bash
set -euo pipefail

REGISTRY_NAME="kind-registry"
REGISTRY_PORT="5000"
REGISTRY_IMAGE="registry:2"

check_docker() {
  if ! docker info &>/dev/null; then
    echo "Docker is not running. Please start Docker and try again."
    exit 1
  fi
}

start_registry() {
  # Start once and keep forever (unless explicitly destroyed)
  if [[ "$(docker ps -q -f name=${REGISTRY_NAME})" == "" ]]; then
    echo "Starting local Docker registry '${REGISTRY_NAME}' on port ${REGISTRY_PORT}..."
    docker run -d --restart=always \
      -p "${REGISTRY_PORT}:5000" --name "${REGISTRY_NAME}" "${REGISTRY_IMAGE}"
  else
    echo "Local registry '${REGISTRY_NAME}' already running."
  fi
}

connect_registry_to_kind_network() {
  # Kind creates a Docker network called "kind"; attach the registry to it
  if ! docker network inspect kind >/dev/null 2>&1; then
    echo "Kind network not found (cluster probably not created yet); skip connect."
    return
  fi
  if ! docker network inspect kind -f '{{range .Containers}}{{.Name}}{{end}}' \
       | grep -q "${REGISTRY_NAME}"; then
    echo "Attaching registry container to Kind network..."
    docker network connect kind "${REGISTRY_NAME}" || true
  fi
}

create_cluster() {
  local cluster_name=$1
  echo "Creating Kubernetes cluster '${cluster_name}' with Kind..."
  kind create cluster \
    --name "${cluster_name}" \
    --config ~/dev-setup/kind/kind-config.yaml
  connect_registry_to_kind_network
  echo "Cluster '${cluster_name}' ready. Push images to localhost:${REGISTRY_PORT}/..."
}

destroy_cluster() {
  local cluster_name=$1
  echo "🗑️  Deleting Kubernetes cluster '${cluster_name}'..."
  kind delete cluster --name "${cluster_name}"

  # If no Kind clusters remain, tear down the registry as well
  if [[ "$(kind get clusters | wc -l)" == "0" ]]; then
    echo "No Kind clusters left; removing local registry..."
    docker rm -f "${REGISTRY_NAME}" 2>/dev/null || true
  fi
}

usage() {
  echo "Usage: $0 {create|destroy} <cluster-name>"
  exit 1
}

main() {
  [[ $# -lt 2 ]] && usage
  action=$1; cluster_name=$2

  case "${action}" in
    create)
      check_docker
      start_registry
      create_cluster "${cluster_name}"
      ;;
    destroy)
      destroy_cluster "${cluster_name}"
      ;;
    *)
      usage
      ;;
  esac
}

main "$@"
