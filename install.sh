#!/usr/bin/env bash

set -euxo pipefail

# 1st Terraform deployment: Azure Databricks workspace and other infra

pushd deployments/infrastructure
    terraform init
    terraform apply
    terraform output > ../workspace/infrastructure.auto.tfvars
    databricks_workspace_host=$(terraform output -raw databricks_workspace_host)
popd


# Databricks CLI profile in which the AAD token is configured.

export TF_VAR_databricks_cli_profile=dbdemo_cli_profile

# Ensure the user is logged in with a User account (not a service principal).
# Databricks CLI AAD token configuration requires a User account.

az account show --query user || az login

# Set up Databricks CLI authentication with an Azure AD token.
# This token is used by a shell script invoked in the 2nd Terraform deployment.

set +x
    token=$(az account get-access-token --resource 2ff814a6-3304-4ab8-85cb-cd0e6f879c1d --query accessToken -o tsv)
    env DATABRICKS_AAD_TOKEN="$token" databricks configure --aad-token --profile "$TF_VAR_databricks_cli_profile" --host "$databricks_workspace_host"
set -x

# 2st Terraform deployment: Azure Databricks configuration

pushd deployments/workspace
    terraform init
    terraform apply
popd