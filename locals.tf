# locals.tf

locals {
  # Render the cloud-init configuration from the template file.
  # The template installs Python, sets up a venv, installs the Snowflake connector,
  # and writes out a test script.
  cloud_init = templatefile("${path.module}/cloud-init.yaml.tmpl", {
    test_script = templatefile("${path.module}/test_snowflake.py.tmpl", {
      snowflake_organization_name = var.snowflake_organization_name
      snowflake_account_name      = var.snowflake_account_name
      azure_tenant_id             = var.azure_tenant_id
      azure_client_id             = local.wif_azure_sp_id_effective
      context_setup = join("\n        ", compact([
        var.wif_default_warehouse != null ? "cur.execute(\"USE WAREHOUSE ${var.wif_default_warehouse}\")\n        print(\"  ✅ Using warehouse: ${var.wif_default_warehouse}\")" : null,
        var.wif_test_database != null ? "cur.execute(\"USE DATABASE ${var.wif_test_database}\")\n        print(\"  ✅ Using database: ${var.wif_test_database}\")" : null,
        var.wif_test_schema != null ? "cur.execute(\"USE SCHEMA ${var.wif_test_schema}\")\n        print(\"  ✅ Using schema: ${var.wif_test_schema}\")" : null
      ]))
      schema_test_query = var.wif_test_database != null && var.wif_test_schema != null ? "try:\n            cur.execute(\"SELECT COUNT(*) as table_count FROM information_schema.tables WHERE table_schema = '${var.wif_test_schema}'\")\n            table_count = cur.fetchone()\n            print(f\"  Tables in schema: {table_count[0]}\")\n        except Exception as e:\n            print(f\"  Schema query info: {str(e)}\")" : "# No schema test query configured"
    })
    snowflake_default_authenticator = "WORKLOAD_IDENTITY"
    snowflake_default_account       = "${var.snowflake_organization_name}-${var.snowflake_account_name}"
    azure_tenant_id                 = var.azure_tenant_id
  })

  # Convenience name tags
  common_tags = merge(
    {
      Project     = "snowflake-wif-azure-test"
      Environment = "test"
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

