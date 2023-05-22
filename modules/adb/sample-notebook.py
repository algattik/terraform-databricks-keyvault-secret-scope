# Databricks notebook source
# MAGIC %md Run a command hitting the SQL Database metastore:

# COMMAND ----------

# MAGIC %sql show tables in samples.nyctaxi

# COMMAND ----------

# MAGIC %md Run a Spark job:

# COMMAND ----------

# MAGIC %sql SELECT * FROM samples.nyctaxi.trips LIMIT 10
