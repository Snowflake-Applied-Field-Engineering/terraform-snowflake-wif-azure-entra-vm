# snowflake.tf
# Snowflake WIF configuration for Azure

# Confirm provider connectivity
data "snowflake_current_account" "this" {}

output "snowflake_current_account" {
  description = "Account locator of the Snowflake account Terraform is connected to"
  value       = data.snowflake_current_account.this.account
}

############################################
# Snowflake WIF role, user, and grants for Azure
############################################

# 0) Determine the Azure Service Principal ID to bind as the workload identity:
#    - If var.azure_service_principal_id is provided, use it
#    - Otherwise, use the managed identity's principal_id (client_id)
locals {
  wif_azure_sp_id_effective = (
    var.azure_service_principal_id != "" ? var.azure_service_principal_id : azurerm_user_assigned_identity.this.client_id
  )
  wif_azure_tenant_id = var.azure_tenant_id
}

# 1) Create the WIF test role in Snowflake
resource "snowflake_account_role" "wif_test_role" {
  name    = var.wif_role_name
  comment = "Role for Azure→Snowflake WIF test user (Terraform-managed)"
}

# 2) Create the WIF service user via exact SQL (TYPE=SERVICE + WORKLOAD_IDENTITY)
#    We use snowflake_execute because the snowflake_user resource does not yet
#    expose WORKLOAD_IDENTITY/TYPE=SERVICE as first-class arguments.
resource "snowflake_execute" "wif_user_create" {
  # Ensure the role exists and the Azure SP ID is resolved first
  depends_on = [
    snowflake_account_role.wif_test_role
  ]

  # CREATE (idempotent), VERIFY (query), and DESTROY (revert)
  execute = <<SQL
CREATE USER IF NOT EXISTS ${var.wif_user_name}
  LOGIN_NAME = ${var.wif_user_login_name}
  TYPE = SERVICE
  DEFAULT_ROLE = ${snowflake_account_role.wif_test_role.name}
  WORKLOAD_IDENTITY = (
    TYPE = AZURE
    AZURE_TENANT_ID = '${local.wif_azure_tenant_id}'
    AZURE_APPLICATION_ID = '${local.wif_azure_sp_id_effective}'
  )
  COMMENT = 'WIF service user (Azure managed identity mapped) managed by Terraform';
SQL

  # Optional visibility during plan/apply
  query = "SHOW USERS LIKE '${var.wif_user_name}';"

  # Clean removal on destroy
  revert = "DROP USER IF EXISTS ${var.wif_user_name};"
}

# 3) Grant the WIF role to the WIF user
resource "snowflake_grant_account_role" "wif_role_to_user" {
  role_name  = snowflake_account_role.wif_test_role.name
  user_name  = var.wif_user_name
  depends_on = [snowflake_execute.wif_user_create]
}

# --- Optional: minimal usage grants so the user can run a quick query ---
# Guard each with count so nulls skip creation.

resource "snowflake_grant_privileges_to_account_role" "wif_wh_usage" {
  count             = var.wif_default_warehouse == null ? 0 : 1
  account_role_name = snowflake_account_role.wif_test_role.name
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = var.wif_default_warehouse
  }
}

resource "snowflake_grant_privileges_to_account_role" "wif_db_usage" {
  count             = var.wif_test_database == null ? 0 : 1
  account_role_name = snowflake_account_role.wif_test_role.name
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "DATABASE"
    object_name = var.wif_test_database
  }
}

resource "snowflake_grant_privileges_to_account_role" "wif_schema_usage" {
  count             = var.wif_test_schema == null ? 0 : 1
  account_role_name = snowflake_account_role.wif_test_role.name
  privileges        = ["USAGE"]
  on_schema {
    schema_name = "${var.wif_test_database}.${var.wif_test_schema}"
  }
}

