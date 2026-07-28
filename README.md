# AKS Context Manager (`ctx`)

A lightweight shell utility for managing Azure Kubernetes Service (AKS) contexts across multiple subscriptions, resource groups, clusters, and regions.

The script works with both **Bash** and **Zsh** and removes the need to remember subscription IDs, resource group names, and AKS cluster names.

---

## Features

✅ Create or refresh AKS contexts

✅ Switch between existing Kubernetes contexts

✅ Delete local Kubernetes contexts

✅ Manage clusters across multiple subscriptions

✅ Support any AKS naming convention

✅ Add new clusters without modifying the script

✅ Shell-compatible (Bash and Zsh)

✅ Dynamically configurable via a local configuration file

✅ Existing kubeconfig contexts remain untouched

---

## Prerequisites

The following tools must be installed and available in your PATH.

### Azure CLI

```bash
az version
```

### kubectl

```bash
kubectl version --client
```

### kubelogin

```bash
kubelogin --version
```

---

## Installation

### Clone the Repository

```bash
git clone https://github.com/murkisairaghava/akscontextswitch.git
cd akscontextswitch
```

### Copy the Script

```bash
mkdir -p ~/scripts

cp contextswitch.sh ~/scripts/
```

### Load the Script Automatically

#### Bash

```bash
echo 'source ~/scripts/contextswitch.sh' >> ~/.bashrc
source ~/.bashrc
```

#### Zsh

```bash
echo 'source ~/scripts/contextswitch.sh' >> ~/.zshrc
source ~/.zshrc
```

---

## Optional Tenant Configuration

If your organisation uses a specific Azure tenant, configure it once in your shell profile.

```bash
export AKS_DEFAULT_TENANT_ID="<tenant-id>"
```

Example:

```bash
echo 'export AKS_DEFAULT_TENANT_ID="<tenant-id>"' >> ~/.zshrc
```

or

```bash
echo 'export AKS_DEFAULT_TENANT_ID="<tenant-id>"' >> ~/.bashrc
```

---

# Cluster Configuration

The script maintains cluster definitions in:

```bash
~/.ctx-clusters.conf
```

Format:

```text
alias|subscription-id|resource-group|aks-name
```

Example:

```text
dev-west|xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx|rg-dev-west|aks-dev-west

dev-east|xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx|rg-dev-east|aks-dev-east

prod-west|yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy|rg-prod-west|aks-prod-west
```

> **Note:** The examples in this README use generic cluster aliases, subscription IDs, resource groups, and AKS names. Replace them with values that match your own Azure environment.

---

# Usage

## Register a Cluster

Register a cluster once before using it.

```bash
ctx add <alias> <subscription-id> <resource-group> <aks-name>
```

Example:

```bash
ctx add dev-west \
xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \
rg-dev-west \
aks-dev-west
```

Another example:

```bash
ctx add prod-west \
yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy \
rg-prod-west \
aks-prod-west
```

---

## Create / Refresh AKS Context

Creates or refreshes the Kubernetes context by:

- Logging into Azure
- Setting the subscription
- Retrieving AKS credentials
- Converting kubeconfig using kubelogin
- Switching to the AKS context

```bash
ctx create <alias>
```

Example:

```bash
ctx create dev-west
```

---

## Switch Context

Switch to an existing Kubernetes context.

```bash
ctx switch <alias>
```

Example:

```bash
ctx switch dev-west
```

---

## Show Current Context

```bash
ctx current
```

Example output:

```text
aks-dev-west
```

---

## List All Kubernetes Contexts

```bash
ctx list
```

Example output:

```text
CURRENT   NAME
*         aks-dev-west
          aks-dev-east
          aks-prod-west
          docker-desktop
```

---

## Show Registered Clusters

Displays all clusters known to the script.

```bash
ctx clusters
```

Example output:

```text
dev-east
dev-west
prod-west
sandbox
```

---

## Delete Kubernetes Context

Deletes a context from the local kubeconfig.

```bash
ctx delete <alias>
```

Example:

```bash
ctx delete dev-west
```

⚠️ This only removes the local Kubernetes context.

It does **not**:

- Delete the AKS cluster
- Delete Azure resources
- Remove subscriptions

---

## Remove Cluster Registration

Removes the cluster definition from the script configuration.

```bash
ctx remove-cluster <alias>
```

Example:

```bash
ctx remove-cluster dev-west
```

⚠️ This does not modify kubeconfig.

Use `ctx delete` if you also want to remove the Kubernetes context.

---

# Example Workflow

### Register Clusters

```bash
ctx add dev-west \
xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \
rg-dev-west \
aks-dev-west

ctx add dev-east \
xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \
rg-dev-east \
aks-dev-east

ctx add prod-west \
yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy \
rg-prod-west \
aks-prod-west
```

### Create Contexts

```bash
ctx create dev-west

ctx create prod-west
```

### Switch Between Contexts

```bash
ctx switch dev-west

ctx switch prod-west
```

### Verify Current Context

```bash
ctx current
```

### List All Contexts

```bash
ctx list
```

### Delete a Local Context

```bash
ctx delete dev-west
```

### Remove Cluster Definition

```bash
ctx remove-cluster dev-west
```

---

# Configuration File Example

Example `~/.ctx-clusters.conf`:

```text
dev-west|xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx|rg-dev-west|aks-dev-west
dev-east|xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx|rg-dev-east|aks-dev-east
prod-west|yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy|rg-prod-west|aks-prod-west
sandbox|zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz|rg-sandbox|aks-sandbox
```

---

# Design Principles

This utility intentionally:

- Does not assume any AKS naming convention
- Does not assume any subscription-to-cluster mapping
- Does not modify existing kubeconfig contexts unless explicitly requested
- Stores cluster definitions separately from the script
- Supports future AKS clusters without code changes
- Works across multiple Azure subscriptions and environments
- Supports both Bash and Zsh

This makes it reusable across teams, subscriptions, environments, and Azure landing zones.

---

# License

This project is licensed under the MIT License - see the LICENSE file for details.
