terraform {
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "=1.14.3"
    }
  }
}

locals {
  secret_scope = "VaultScope"
}

data "databricks_node_type" "smallest" {
  local_disk = true
}

data "databricks_spark_version" "latest_lts" {
  long_term_support = true
}

data "azurerm_key_vault_secret" "db-un" {
  name         = var.metastore_username_secret_name
  key_vault_id = var.key_vault_id
}

data "azurerm_key_vault_secret" "db-pw" {
  name         = var.metastore_password_secret_name
  key_vault_id = var.key_vault_id
}

resource "null_resource" "secret_scope" {
  triggers = {
    databricks_cli_profile = var.databricks_cli_profile
    secret_scope           = local.secret_scope
    key_vault_id           = var.key_vault_id
    key_vault_uri          = var.key_vault_uri
  }

  provisioner "local-exec" {
    command = <<EOT
      databricks secrets create-scope \
        --profile "${self.triggers.databricks_cli_profile}" \
        --scope "${self.triggers.secret_scope}" \
        --scope-backend-type AZURE_KEYVAULT \
        --resource-id "${self.triggers.key_vault_id}" \
        --dns-name "${self.triggers.key_vault_uri}"
    EOT
  }

  provisioner "local-exec" {
    when = destroy

    command = <<EOT
      databricks secrets delete-scope \
        --profile "${self.triggers.databricks_cli_profile}" \
        --scope "${self.triggers.secret_scope}"
    EOT
  }
}

resource "databricks_cluster" "shared_autoscaling" {
  cluster_name            = "demo-cluster"
  spark_version           = data.databricks_spark_version.latest_lts.id
  node_type_id            = data.databricks_node_type.smallest.id
  autotermination_minutes = 20
  autoscale {
    min_workers = 1
    max_workers = 2
  }
  spark_conf = {
    # Metastore config
    "spark.hadoop.javax.jdo.option.ConnectionDriverName" : "com.microsoft.sqlserver.jdbc.SQLServerDriver",
    "spark.hadoop.javax.jdo.option.ConnectionURL" : var.metastore_jdbc_connection_string
    "spark.hadoop.javax.jdo.option.ConnectionUserName" : data.azurerm_key_vault_secret.db-un.value,
    "spark.hadoop.javax.jdo.option.ConnectionPassword" : " {{secrets/${local.secret_scope}/${var.metastore_password_secret_name}}}",
    "datanucleus.fixedDatastore" : false,
    "datanucleus.autoCreateSchema" : true,
    "hive.metastore.schema.verification" : false,
    "datanucleus.schema.autoCreateTables" : true,
  }
}

resource "databricks_notebook" "sample-notebook" {
  source = "${path.module}/sample-notebook.py"
  path   = "/Shared/sample-notebook"
}

resource "databricks_job" "sample-job" {
  name = "Sample job"

  task {
    task_key = "a"

    existing_cluster_id = databricks_cluster.shared_autoscaling.id

    notebook_task {
      notebook_path = databricks_notebook.sample-notebook.path
    }
  }

  schedule {
    quartz_cron_expression = "0 * * * * ?" # every minute
    timezone_id            = "UTC"
  }
}