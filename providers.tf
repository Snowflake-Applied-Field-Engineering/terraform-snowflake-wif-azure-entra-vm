terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "~> 1.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# Azure Resource Manager Provider
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    virtual_machine {
      delete_os_disk_on_deletion     = true
      skip_shutdown_and_force_delete = false
    }
  }
  subscription_id = var.azure_subscription_id
}

# Azure Active Directory Provider
provider "azuread" {
  tenant_id = var.azure_tenant_id
}

# Snowflake Provider
# Authentication Options:
# Option A: Key-pair authentication (current configuration)
# Option B: OAuth - comment out below and use OAuth variables instead

provider "snowflake" {
  organization_name = var.snowflake_organization_name
  account_name      = var.snowflake_account_name
  user              = var.snowflake_username
  role              = var.snowflake_role
  authenticator     = "SNOWFLAKE_JWT" # Requires private_key and corresponding public key setup
  private_key       = file(var.snowflake_private_key_path)

  # Optional: Enable preview features if needed
  # preview_features_enabled = []
}

