# outputs.tf

# --- Azure outputs ---

output "resource_group_name" {
  description = "Name of the Azure resource group"
  value       = azurerm_resource_group.this.name
}

output "vm_id" {
  description = "ID of the Azure VM"
  value       = azurerm_linux_virtual_machine.this.id
}

output "vm_name" {
  description = "Name of the Azure VM"
  value       = azurerm_linux_virtual_machine.this.name
}

output "vm_private_ip" {
  description = "Private IP address of the Azure VM"
  value       = azurerm_network_interface.this.private_ip_address
}

output "vm_public_ip" {
  description = "Public IP address of the Azure VM (if enabled)"
  value       = var.enable_public_ip ? azurerm_public_ip.this[0].ip_address : null
}

output "managed_identity_principal_id" {
  description = "Principal ID (Object ID) of the user-assigned managed identity"
  value       = azurerm_user_assigned_identity.this.principal_id
}

output "managed_identity_client_id" {
  description = "Client ID (Application ID) of the user-assigned managed identity"
  value       = azurerm_user_assigned_identity.this.client_id
}

output "managed_identity_id" {
  description = "Resource ID of the user-assigned managed identity"
  value       = azurerm_user_assigned_identity.this.id
}

output "ssh_private_key" {
  description = "Generated SSH private key (if SSH key was auto-generated)"
  value       = var.ssh_public_key_path == "" && var.admin_password == null ? tls_private_key.ssh[0].private_key_pem : "Not generated - using provided key or password"
  sensitive   = true
}

output "ssh_connection_command" {
  description = "Command to SSH into the VM (if public IP is enabled)"
  value = var.enable_public_ip ? (
    var.ssh_public_key_path != "" || var.admin_password == null ?
    "ssh -i <your-private-key> ${var.admin_username}@${azurerm_public_ip.this[0].ip_address}" :
    "Use Azure Portal or az ssh vm command"
  ) : "No public IP - use Azure Bastion or private network access"
}

output "azure_cli_ssh_command" {
  description = "Azure CLI command to SSH into the VM"
  value       = "az ssh vm -n ${azurerm_linux_virtual_machine.this.name} -g ${azurerm_resource_group.this.name}"
}

# --- Snowflake outputs ---

output "snowflake_account_name" {
  description = "Snowflake account locator used for provider/resources"
  value       = var.snowflake_account_name
}

output "snowflake_role_used" {
  description = "Snowflake role leveraged by Terraform when applying resources"
  value       = var.snowflake_role
}

output "wif_azure_sp_id_effective" {
  description = "Azure Service Principal (Application) ID mapped to the Snowflake WIF user"
  value       = local.wif_azure_sp_id_effective
}

output "wif_azure_tenant_id" {
  description = "Azure AD Tenant ID used for WIF configuration"
  value       = local.wif_azure_tenant_id
}

output "wif_test_role" {
  description = "Snowflake role created for WIF testing"
  value       = snowflake_account_role.wif_test_role.name
}

output "wif_test_user" {
  description = "Snowflake WIF user created via WORKLOAD_IDENTITY"
  value       = var.wif_user_name
}

# --- Convenience outputs ---

output "test_instructions" {
  description = "Instructions for testing the WIF connection"
  value       = <<-EOT
    
    === Snowflake WIF Test Instructions ===
    
    1. Connect to the VM:
       ${var.enable_public_ip ? "SSH: ssh ${var.admin_username}@${var.enable_public_ip ? azurerm_public_ip.this[0].ip_address : "N/A"}" : ""}
       Azure CLI: az ssh vm -n ${azurerm_linux_virtual_machine.this.name} -g ${azurerm_resource_group.this.name}
    
    2. Once connected, run:
       sudo su -
       source /opt/snowflake-test/venv/bin/activate
       python3 /opt/snowflake-test/test_snowflake.py
    
    3. The test script will:
       - Use the VM's managed identity to obtain an Azure AD token
       - Authenticate to Snowflake using WIF
       - Execute test queries to verify connectivity
    
    === Configuration Details ===
    Snowflake Account: ${var.snowflake_organization_name}-${var.snowflake_account_name}
    WIF User: ${var.wif_user_name}
    WIF Role: ${var.wif_role_name}
    Azure Tenant ID: ${var.azure_tenant_id}
    Azure Application ID: ${local.wif_azure_sp_id_effective}
    
  EOT
}

