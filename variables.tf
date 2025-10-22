# variables.tf

# Azure Infrastructure Variables
variable "azure_subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "azure_tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
}

variable "location" {
  description = "Azure region to deploy into (e.g., eastus, westus2)"
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Name of the Azure resource group (will be created if it doesn't exist)"
  type        = string
  default     = "rg-snowflake-wif-test"
}

variable "vnet_name" {
  description = "Name of existing VNet (leave empty to create new)"
  type        = string
  default     = ""
}

variable "subnet_name" {
  description = "Name of existing subnet (leave empty to create new)"
  type        = string
  default     = ""
}

variable "vnet_address_space" {
  description = "Address space for VNet if creating new (CIDR notation)"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_address_prefix" {
  description = "Address prefix for subnet if creating new (CIDR notation)"
  type        = string
  default     = "10.0.1.0/24"
}

variable "name_prefix" {
  description = "Prefix to apply to resource names"
  type        = string
  default     = "snow-wif-test"
}

variable "vm_size" {
  description = "Azure VM size"
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key for VM access (optional, leave empty for password auth)"
  type        = string
  default     = ""
}

variable "admin_password" {
  description = "Admin password for the VM (required if ssh_public_key_path is empty)"
  type        = string
  sensitive   = true
  default     = null
}

variable "os_image" {
  description = "OS image to use for VM"
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

variable "enable_public_ip" {
  description = "Whether to create and assign a public IP to the VM"
  type        = bool
  default     = true
}

variable "allow_ssh_from_internet" {
  description = "Whether to allow SSH from internet (0.0.0.0/0) - not recommended for production"
  type        = bool
  default     = false
}

variable "ssh_source_address_prefixes" {
  description = "List of CIDR blocks allowed to SSH to the VM"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Map of tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Snowflake Provider Variables
variable "snowflake_organization_name" {
  description = "Snowflake organization name"
  type        = string
}

variable "snowflake_account_name" {
  description = "Snowflake account locator (e.g., xy12345 or xy12345.us-east-1)"
  type        = string
}

variable "snowflake_role" {
  description = "Default role to use when applying Terraform resources in Snowflake"
  type        = string
}

variable "snowflake_username" {
  description = "Default user to use when applying Terraform resources in Snowflake"
  type        = string
}

variable "snowflake_private_key_path" {
  description = "Path to the PKCS#8 private key for Snowflake authentication"
  type        = string
}

variable "snowflake_private_key_passphrase" {
  description = "Passphrase for the private key (if encrypted)"
  type        = string
  sensitive   = true
  default     = ""
}

# Snowflake WIF Identity Objects
variable "wif_user_name" {
  description = "Name of the Snowflake WIF test user (e.g., WIF_TEST_USER)"
  type        = string
  default     = "WIF_TEST_USER"
}

variable "wif_role_name" {
  description = "Name of the WIF test role"
  type        = string
  default     = "WIF_TEST_ROLE"
}

# Optional Snowflake Context for Testing
variable "wif_default_warehouse" {
  description = "Default warehouse for the WIF test user/role (must exist)"
  type        = string
  default     = null
}

variable "wif_test_database" {
  description = "Database to test privileges of the WIF test user/role (must exist)"
  type        = string
  default     = null
}

variable "wif_test_schema" {
  description = "Schema to test privileges of the WIF test user/role (must exist)"
  type        = string
  default     = null
}

# Azure WIF Identity Override
variable "azure_service_principal_id" {
  description = "Optional Override - Azure AD Service Principal (Application) ID to use for WIF (if not provided, uses managed identity)"
  type        = string
  default     = ""
}

