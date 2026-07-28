# AKS Context Manager (`ctx`)

A lightweight shell utility for managing Azure Kubernetes Service (AKS) contexts across multiple subscriptions, resource groups, clusters, and regions.

The script works with both **Bash** and **Zsh** and removes the need to remember subscription IDs, resource group names, and AKS cluster names.

***

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

***

## Prerequisites

The following tools must be installed and available in your PATH:

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

***

## Installation

### Clone the repository

```bash
git clone https://github.com/murkisairaghava/akscontextswitch.git
cd akscontextswitch
```

### Copy the script

```bash
mkdir -p ~/scripts

cp contextswitch.sh ~/scripts/
```

### Load the script automatically

#### Bash

```bash
echo 'source ~/scripts/ctx.sh' >> ~/.bashrc
source ~/.bashrc
```

#### Zsh

```bash
echo 'source ~/scripts/ctx.sh' >> ~/.zshrc
source ~/.zshrc
```

***

## Optional Tenant Configuration

If your organisation uses a specific Azure tenant, configure it once in your shell profile.

```bash
export AKS_DEFAULT_TENANT_ID="<tenant-id>"
```

Examples:

```bash
echo 'export AKS_DEFAULT_TENANT_ID="<tenant-id>"' >> ~/.zshrc
```

or

```bash
echo 'export AKS_DEFAULT_TENANT_ID="<tenant-id>"' >> ~/.bashrc
```

***

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
papa-we|f1edad0e-3c56-4c3a-854d-5f76d51b6f9c|rg-np-we-p30119-papa|aks-np-we-p30119-papa

papa-ne|f1edad0e-3c56-4c3a-854d-5f76d51b6f9c|rg-np-ne-p30119-papa|aks-np-ne-p30119-papa

mpeudt-we|27d1246d-e682-4008-8105-50e8bd033fa6|rg-np-we-p30119-mpeudt|aks-np-we-p30119-mpeudt
```

This design allows the script to work with any AKS naming convention.

***

# Usage

## Register a Cluster

Register a cluster once before using it.

```bash
ctx add <alias> <subscription-id> <resource-group> <aks-name>
```

Example:

```bash
ctx add prod-west \
12345678-1234-1234-1234-123456789abc \
rg-production-west \
aks-production-west
```

***

## Create / Refresh AKS Context

Creates or refreshes the Kubernetes context by:

* Logging into Azure
* Setting the subscription
* Retrieving AKS credentials
* Converting kubeconfig using kubelogin
* Switching to the AKS context

```bash
ctx create <alias>
```

Example:

```bash
ctx create papa-we
```

***

## Switch Context

Switch to an existing Kubernetes context.

```bash
ctx switch <alias>
```

Example:

```bash
ctx switch prod-west
```

***

## Show Current Context

```bash
ctx current
```

Example output:

```text
aks-production-west
```

***

## List All Kubernetes Contexts

```bash
ctx list
```

Example:

```text
CURRENT   NAME
*         aks-production-west
          aks-development-north
          docker-desktop
```

***

## Show Registered Clusters

Displays all clusters known to the script.

```bash
ctx clusters
```

Example:

```text
dev-we
acc-we
production-west
production-north
```

***

## Delete Kubernetes Context

Deletes a context from the local kubeconfig.

```bash
ctx delete <alias>
```

Example:

```bash
ctx delete development-west
```

⚠️ This only removes the local Kubernetes context.

It does **not**:

* delete the AKS cluster
* delete Azure resources
* remove subscriptions

***

## Remove Cluster Registration

Removes the cluster definition from the script configuration.

```bash
ctx remove-cluster <alias>
```

Example:

```bash
ctx remove-cluster development-west
```

⚠️ This does not modify kubeconfig.

Use `ctx delete` if you also want to remove the Kubernetes context.

***

# Example Workflow

### Register clusters

```bash
ctx add production-west \
12345678-1234-1234-1234-123456789abc \
rg-aks-production \
aks-west-production

```

### Create contexts

```bash
ctx create production-west
ctx create development-north
```

### Switch between contexts

```bash
ctx switch production-west

ctx switch production-north
```

### Verify current context

```bash
ctx current
```

### List all contexts

```bash
ctx list
```

### Delete a local context

```bash
ctx delete development-west
```

### Remove cluster definition

```bash
ctx remove-cluster development-west
```

***

# Design Principles

The script intentionally:

* Does not assume any AKS naming convention
* Does not assume subscription-to-cluster mappings
* Does not modify existing kubeconfig contexts unless explicitly requested
* Keeps cluster definitions separate from the script
* Supports future AKS clusters without code changes

This makes it reusable across teams, subscriptions, environments, and Azure landing zones.

***

