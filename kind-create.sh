#!/usr/bin/env bash
# ----------------------------------------------------------------------------
# kind-create.sh          - Manage local Kind clusters backed by a private
#                           Docker registry.
#
# USAGE:
#   KIND_CONFIG=./kind-config.yaml \
#   REGISTRY_PORT=5001 \
#   ./kind_cluster_manager.sh create my-cluster
#
# FLAGS / ENV VARS:
#   REGISTRY_NAME   - Docker container name for the registry (default: kind-registry)
#   REGISTRY_PORT   - Host port exposed by the local registry (default: 5000)
#   REGISTRY_IMAGE  - Registry image (default: registry:2)
#   KIND_CONFIG     - Path to Kind cluster configuration file
#
# REQUIREMENTS:
#   * docker ≥ 20.x
#   * kind  ≥ 0.22.0  (https://kind.sigs.k8s.io/)
# ----------------------------------------------------------------------------
set -euo pipefail

REGISTRY_NAME=${REGISTRY_NAME:-kind-registry}
REGISTRY_PORT=${REGISTRY_PORT:-5000}
REGISTRY_IMAGE=${REGISTRY_IMAGE:-registry:2}
KIND_CONFIG=${KIND_CONFIG:-"./kind-config.yaml"}

# -----------------------------------------------------------------------------
# Helper functions
# -----------------------------------------------------------------------------
require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" &>/dev/null; then
    echo "Required command '$cmd' not found in PATH. Please install it and try again." >&2
    exit 1
  fi
}

check_prereqs() {
  require_cmd docker
  require_cmd kind
  if ! docker info &>/dev/null; then
    echo "Docker daemon is not running. Start Docker and retry." >&2
    exit 1
  fi
}

check_kind_config() {
  if [[ ! -f "$KIND_CONFIG" ]]; then
    echo "Kind config file '$KIND_CONFIG' not found.\n   Export KIND_CONFIG to point to the correct file or create the file first." >&2
    exit 1
  fi
}

start_registry() {
  if [[ -z "$(docker ps -q -f name="$REGISTRY_NAME")" ]]; then
    echo "Starting local Docker registry '$REGISTRY_NAME' on port $REGISTRY_PORT ..."
    docker run -d --restart=always -p "$REGISTRY_PORT:5000" --name "$REGISTRY_NAME" "$REGISTRY_IMAGE"
  else
    echo "Registry '$REGISTRY_NAME' already running."
  fi
}

connect_registry_to_kind_network() {
  if ! docker network inspect kind >/dev/null 2>&1; then
    echo "Kind network not found (cluster likely not created yet); skipping registry attach."
    return
  fi
  if ! docker network inspect kind -f '{{range .Containers}}{{.Name}}{{end}}' | grep -q "$REGISTRY_NAME"; then
    echo "Attaching registry container to Kind network ..."
    docker network connect kind "$REGISTRY_NAME" || true
  fi
}

create_cluster() {
  local cluster_name="$1"
  echo "Creating Kubernetes cluster '$cluster_name' with Kind ..."
  kind create cluster \
    --name "$cluster_name" \
    --config "$KIND_CONFIG"
  connect_registry_to_kind_network
  echo "Cluster '$cluster_name' ready. Push images to localhost:$REGISTRY_PORT/ ..."
}

destroy_cluster() {
  local cluster_name="$1"
  echo "Deleting Kubernetes cluster '$cluster_name' ..."
  kind delete cluster --name "$cluster_name"

  if [[ "$(kind get clusters | wc -l)" == "0" ]]; then
    echo "🧹 No Kind clusters remain; removing local registry ..."
    docker rm -f "$REGISTRY_NAME" 2>/dev/null || true
  fi
}

usage() {
  cat <<EOF
Usage: $0 {create|destroy} <cluster-name>

Optional environment variables:
  REGISTRY_NAME   (default: $REGISTRY_NAME)
  REGISTRY_PORT   (default: $REGISTRY_PORT)
  REGISTRY_IMAGE  (default: $REGISTRY_IMAGE)
  KIND_CONFIG     (default: $KIND_CONFIG)
EOF
  exit 1
}

main() {
  [[ $# -lt 2 ]] && usage
  local action="$1"; shift
  local cluster_name="$1"

  case "$action" in
    create)
      check_prereqs
      check_kind_config
      start_registry
      create_cluster "$cluster_name"
      ;;
    destroy)
      check_prereqs  # still need docker & kind to clean up
      destroy_cluster "$cluster_name"
      ;;
    *)
      usage
      ;;
  esac
}

main "$@"
