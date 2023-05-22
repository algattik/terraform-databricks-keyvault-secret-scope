# Databricks Terraform sample

## Scope

## Deploying the solution

Run:

```shell
terraform init
terraform apply
```

⚠️ This sets up a cluster of one node, and a recurring job every minute, so that the cluster never automatically shuts down. This will incur high costs if you forget to tear down the resources!

## About the solution

### Overview

The solution deploys Azure Databricks. A Databricks job runs periodically.

The cluster is configured to use an external Hive metastore in Azure SQL Database.
