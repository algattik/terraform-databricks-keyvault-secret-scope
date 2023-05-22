# Databricks Terraform sample

## Scope

This sample showcases automating the deployment of an Azure Databricks KeyVault-backed secret scope using Terraform.

## Deploying the solution

Run:

```shell
./install.sh
```

When prompted (twice), answer `yes`.

⚠️ This sets up a cluster of one node, and a recurring job every minute, so that the cluster never automatically shuts down. This will incur high costs if you forget to tear down the resources!

## About the solution

### Overview

The solution deploys Azure Databricks. A Databricks job runs periodically.

The cluster is configured to use an external Hive metastore in Azure SQL Database. The password of the database user is stored in Azure Key Vault.

The functionality to deploy a KeyVault-backed secret scope is not currently supported in Terraform. The solution showcases using shell scripts and the Databricks CLI to circumvent this limitation.	

The script [install.sh](install.sh):

- Performs a first Terraform deployment that sets up the Databricks workspace and other infrastructure.
- Configures Databricks CLI with an AAD token.
- Performs a second Terraform deployment that provisions the workspace content. This includes setting up the KeyVault-backed secret scope using Databricks CLI.
