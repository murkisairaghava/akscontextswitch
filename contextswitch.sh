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

  ctx add papa-we \
    f1edad0e-3c56-4c3a-854d-5f76d51b6f9c \
    rg-np-we-p30119-papa \
    aks-np-we-p30119-papa

  ctx create papa-we

  ctx switch papa-we

  ctx delete papa-we

  ctx remove-cluster papa-we

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
