#!/usr/bin/env sh

# ============================================================
# Generic AKS Context Manager
# ============================================================

AKS_DEFAULT_TENANT_ID="${AKS_DEFAULT_TENANT_ID:-}"
export AKS_DEFAULT_TENANT_ID

CTX_CLUSTER_CONFIG="${CTX_CLUSTER_CONFIG:-$HOME/.ctx-clusters.conf}"
export CTX_CLUSTER_CONFIG

# ------------------------------------------------------------
# Config File
# ------------------------------------------------------------

_ctx_init_config() {
    mkdir -p "$(dirname "$CTX_CLUSTER_CONFIG")"

    if [ ! -f "$CTX_CLUSTER_CONFIG" ]; then
        touch "$CTX_CLUSTER_CONFIG"
    fi
}

# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------

_get_cluster_line() {
    alias_name="$1"

    _ctx_init_config

    grep "^${alias_name}|" "$CTX_CLUSTER_CONFIG" | tail -1
}

_get_subscription() {
    _get_cluster_line "$1" | cut -d'|' -f2
}

_get_resource_group() {
    _get_cluster_line "$1" | cut -d'|' -f3
}

_get_aks_name() {
    _get_cluster_line "$1" | cut -d'|' -f4
}

_cluster_exists() {
    [ -n "$(_get_cluster_line "$1")" ]
}

# ------------------------------------------------------------
# Add Cluster
# ------------------------------------------------------------

_ctx_add() {

    alias_name="$1"
    subscription="$2"
    resource_group="$3"
    aks_name="$4"

    if [ -z "$alias_name" ] || \
       [ -z "$subscription" ] || \
       [ -z "$resource_group" ] || \
       [ -z "$aks_name" ]; then

        echo "Usage:"
        echo "  ctx add <alias> <subscription-id> <resource-group> <aks-name>"
        return 1
    fi

    _ctx_init_config

    tmp_file="${CTX_CLUSTER_CONFIG}.tmp.$$"

    grep -v "^${alias_name}|" "$CTX_CLUSTER_CONFIG" > "$tmp_file" 2>/dev/null || true

    echo "${alias_name}|${subscription}|${resource_group}|${aks_name}" >> "$tmp_file"

    mv "$tmp_file" "$CTX_CLUSTER_CONFIG"

    echo "Cluster registered:"
    echo "  Alias: $alias_name"
}

# ------------------------------------------------------------
# Remove Cluster Registration
# ------------------------------------------------------------

_ctx_remove_cluster() {

    alias_name="$1"

    if [ -z "$alias_name" ]; then
        echo "Usage:"
        echo "  ctx remove-cluster <alias>"
        return 1
    fi

    tmp_file="${CTX_CLUSTER_CONFIG}.tmp.$$"

    grep -v "^${alias_name}|" "$CTX_CLUSTER_CONFIG" > "$tmp_file"

    mv "$tmp_file" "$CTX_CLUSTER_CONFIG"

    echo "Removed cluster:"
    echo "  $alias_name"
}

# ------------------------------------------------------------
# Create Context
# ------------------------------------------------------------

_ctx_create() {

    alias_name="$1"

    if [ -z "$alias_name" ]; then
        echo "Usage:"
        echo "  ctx create <alias>"
        return 1
    fi

    if ! _cluster_exists "$alias_name"; then
        echo "Unknown cluster:"
        echo "  $alias_name"
        return 1
    fi

    subscription="$(_get_subscription "$alias_name")"
    resource_group="$(_get_resource_group "$alias_name")"
    aks_name="$(_get_aks_name "$alias_name")"

    echo "Creating context for:"
    echo "  Alias: $alias_name"
    echo "  Subscription: $subscription"
    echo "  Resource Group: $resource_group"
    echo "  AKS Name: $aks_name"

    if [ -n "$AKS_DEFAULT_TENANT_ID" ]; then
        az login --tenant "$AKS_DEFAULT_TENANT_ID"
    else
        az login
    fi

    az account set --subscription "$subscription"

    az aks get-credentials \
      --resource-group "$resource_group" \
      --name "$aks_name" \
      --overwrite-existing

    kubelogin convert-kubeconfig -l azurecli

    kubectl config use-context "$aks_name"

    echo ""
    echo "Current context:"
    kubectl config current-context
}

# ------------------------------------------------------------
# Switch Context
# ------------------------------------------------------------

_ctx_switch() {

    alias_name="$1"

    if ! _cluster_exists "$alias_name"; then
        echo "Unknown cluster:"
        echo "  $alias_name"
        return 1
    fi

    aks_name="$(_get_aks_name "$alias_name")"

    kubectl config use-context "$aks_name"
}

# ------------------------------------------------------------
# Delete Context
# ------------------------------------------------------------

_ctx_delete() {

    alias_name="$1"

    if ! _cluster_exists "$alias_name"; then
        echo "Unknown cluster:"
        echo "  $alias_name"
        return 1
    fi

    aks_name="$(_get_aks_name "$alias_name")"

    kubectl config delete-context "$aks_name"
}

# ------------------------------------------------------------
# Show Clusters
# ------------------------------------------------------------

_ctx_clusters() {

    _ctx_init_config

    if [ ! -s "$CTX_CLUSTER_CONFIG" ]; then
        echo "No clusters configured."
        echo ""
        echo "Use:"
        echo "  ctx add <alias> <subscription-id> <resource-group> <aks-name>"
        return
    fi

    cut -d'|' -f1 "$CTX_CLUSTER_CONFIG" | sort
}

# ------------------------------------------------------------
# Help
# ------------------------------------------------------------

_ctx_help() {

cat <<EOF

AKS Context Manager

Commands:

  ctx add <alias> <subscription-id> <resource-group> <aks-name>

  ctx create <alias>

  ctx switch <alias>

  ctx delete <alias>

  ctx remove-cluster <alias>

  ctx clusters

  ctx list

  ctx current

Examples:

  # Register a cluster

  ctx add dev-west \
    xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \
    rg-dev-west \
    aks-dev-west

  # Create or refresh AKS context

  ctx create dev-west

  # Switch to an existing context

  ctx switch dev-west

  # Delete a local kubeconfig context

  ctx delete dev-west

  # Remove a registered cluster definition

  ctx remove-cluster dev-west

  # Register another cluster

  ctx add prod-east \
    yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy \
    rg-prod-east \
    aks-prod-east

  ctx create prod-east

Useful commands:

  ctx clusters
      Show all configured cluster aliases

  ctx list
      List all Kubernetes contexts in kubeconfig

  ctx current
      Show currently active Kubernetes context

Configuration:

  Cluster definitions are stored in:

      $CTX_CLUSTER_CONFIG

  Format:

      alias|subscription-id|resource-group|aks-name

  Example:

      dev-west|xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx|rg-dev-west|aks-dev-west
      prod-east|yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy|rg-prod-east|aks-prod-east

Notes:

  - The script does not assume any AKS naming convention.
  - The script does not modify existing kubeconfig contexts
    unless explicitly requested.
  - Cluster definitions are stored separately from the script.
  - New clusters can be added without modifying the script.
  - Works with both Bash and Zsh.

EOF
}

# ------------------------------------------------------------
# Main Router
# ------------------------------------------------------------

ctx() {

    command="$1"

    case "$command" in

        add)
            shift
            _ctx_add "$@"
            ;;

        create)
            shift
            _ctx_create "$@"
            ;;

        switch)
            shift
            _ctx_switch "$@"
            ;;

        delete)
            shift
            _ctx_delete "$@"
            ;;

        remove-cluster)
            shift
            _ctx_remove_cluster "$@"
            ;;

        clusters)
            _ctx_clusters
            ;;

        list)
            kubectl config get-contexts
            ;;

        current)
            kubectl config current-context
            ;;

        help|-h|--help|"")
            _ctx_help
            ;;

        *)
            echo "Unknown command:"
            echo "  $command"
            ;;
    esac
}

_ctx_init_config
``
