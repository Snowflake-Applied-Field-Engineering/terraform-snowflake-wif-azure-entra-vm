# ❄️ Snowflake Workload Identity Federation (WIF) Test Environment (Azure)

A Terraform module to deploy a test **Azure Virtual Machine (VM)** for testing **Snowflake Workload Identity Federation (WIF)**. This enables secure authentication to Snowflake using an **Azure AD Managed Identity**, eliminating the need for password or key-based credentials.

[![Terraform Validation](https://github.com/Snowflake-Applied-Field-Engineering/snowflake-wif-azure-sp/actions/workflows/terraform-validate.yml/badge.svg)](https://github.com/Snowflake-Applied-Field-Engineering/snowflake-wif-azure-sp/actions/workflows/terraform-validate.yml)

---

## Table of Contents

- [Architecture Summary](#architecture-summary)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)
- [Security Considerations](#security-considerations)
- [Cleanup](#cleanup)

---

## Architecture Summary

This module creates the following resources:

### In Azure:

* **Azure Virtual Machine (VM)** - Ubuntu 22.04 LTS VM in your specified subnet
* **User-Assigned Managed Identity** - The VM uses this identity to authenticate
* **Network Security Group (NSG)** - Minimal security rules for SSH and outbound HTTPS
* **Virtual Network & Subnet** - Creates new or uses existing VNet/subnet
* **Public IP** (Optional) - For direct SSH access to the VM

### In Snowflake:

* **Database Role** (`WIF_TEST_ROLE`) - Role with necessary permissions for testing
* **Service User** (`WIF_TEST_USER`) - Configured with Azure AD Service Principal ID to enable `WORKLOAD_IDENTITY` authentication
* **Permission Grants** - Usage permissions on warehouse, database, and schema

---

##  Prerequisites

### Required Tools

* **Terraform** >= 1.5.0
* **Azure CLI** configured and authenticated (`az login`)
* **Snowflake Account** with ACCOUNTADMIN privileges

### Required Permissions

#### Azure:
* Ability to create VMs, Managed Identities, and Network resources
* Access to Azure AD for Service Principal configuration

#### Snowflake:
* ACCOUNTADMIN role or equivalent to create users and roles
* Existing warehouse, database, and schema for testing

### Azure CLI Setup

```bash
# Login to Azure
az login

# Set your subscription
az account set --subscription "your-subscription-id"

# Verify your account
az account show
```

---

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/Snowflake-Applied-Field-Engineering/snowflake-wif-azure-sp.git
cd snowflake-wif-azure-sp
```

### 2. Configure Variables

Create a `terraform.tfvars` file with your specific values:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
# Azure Infrastructure
azure_subscription_id = "your-subscription-id"
azure_tenant_id       = "your-tenant-id"
location              = "eastus"
resource_group_name   = "rg-snowflake-wif-test"

# VM Configuration
vm_size        = "Standard_B2s"
admin_username = "azureuser"
ssh_public_key_path = "~/.ssh/id_rsa.pub"

# Network Security
enable_public_ip           = true
allow_ssh_from_internet    = false
ssh_source_address_prefixes = ["YOUR.IP.ADDRESS/32"]

# Snowflake Provider Authentication (for Terraform)
snowflake_organization_name = "your_org_name"
snowflake_account_name      = "your_account_locator"
snowflake_username          = "your_terraform_user"
snowflake_role              = "ACCOUNTADMIN"
snowflake_private_key_path  = "/path/to/snowflake_rsa_key.p8"

# WIF Test Resources
wif_user_name         = "WIF_TEST_USER"
wif_role_name         = "WIF_TEST_ROLE"
wif_default_warehouse = "COMPUTE_WH"
wif_test_database     = "TEST_DB"
wif_test_schema       = "PUBLIC"
```

### 3. Deploy the Infrastructure

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

### 4. Connect and Test

After deployment, connect to the VM using one of these methods:

#### Option A: Azure CLI (Recommended)

```bash
# Get the VM name from Terraform output
VM_NAME=$(terraform output -raw vm_name)
RG_NAME=$(terraform output -raw resource_group_name)

# Connect using Azure CLI
az ssh vm -n $VM_NAME -g $RG_NAME
```

#### Option B: Direct SSH (if public IP is enabled)

```bash
# Get the public IP
PUBLIC_IP=$(terraform output -raw vm_public_ip)

# SSH to the VM
ssh azureuser@$PUBLIC_IP
```

### 5. Run the WIF Test

Once connected to the VM:

```bash
# Switch to root
sudo su -

# Run the test script (convenience command)
test-snowflake-wif

# Or manually:
source /opt/snowflake-test/venv/bin/activate
python3 /opt/snowflake-test/test_snowflake.py
```

Expected output:

```
============================================================
Snowflake WIF Connection Test (Azure)
============================================================
Snowflake Connector Version: 3.17.0

[Step 1] Obtaining Azure AD token using managed identity...
Obtaining Azure AD token for tenant: your-tenant-id
Using managed identity client ID: your-client-id
✅ Successfully obtained Azure AD token

[Step 2] Connecting to Snowflake using WIF...
Account: your-org-your-account
✅ WIF Connection established successfully!

[Step 3] Setting Snowflake context...
  ✅ Using warehouse: COMPUTE_WH
  ✅ Using database: TEST_DB
  ✅ Using schema: PUBLIC

[Step 4] Executing test queries...
  Current timestamp: 2025-10-22 15:30:45.123

============================================================
🎉 WIF Connection Successful!
============================================================
  User: WIF_TEST_USER
  Account: YOUR_ACCOUNT
  Role: WIF_TEST_ROLE
  Warehouse: COMPUTE_WH
  Database: TEST_DB
  Schema: PUBLIC
============================================================

✅ WIF test completed successfully! Connection and permissions verified.
```

---

## ⚙️ Configuration

### Network Configuration

#### Use Existing VNet/Subnet

```hcl
vnet_name   = "my-existing-vnet"
subnet_name = "my-existing-subnet"
```

#### Create New VNet/Subnet

```hcl
vnet_name             = ""  # Leave empty
subnet_name           = ""  # Leave empty
vnet_address_space    = ["10.0.0.0/16"]
subnet_address_prefix = "10.0.1.0/24"
```

### Authentication Methods

#### SSH Key Authentication (Recommended)

```hcl
ssh_public_key_path = "~/.ssh/id_rsa.pub"
```

#### Auto-Generated SSH Key

```hcl
ssh_public_key_path = ""  # Leave empty
admin_password      = null
```

The private key will be available in Terraform outputs (sensitive).

#### Password Authentication

```hcl
ssh_public_key_path = ""
admin_password      = "YourSecurePassword123!"
```

### OS Image Selection

Default is Ubuntu 22.04 LTS. To use a different image:

```hcl
os_image = {
  publisher = "Canonical"
  offer     = "0001-com-ubuntu-server-jammy"
  sku       = "22_04-lts-gen2"
  version   = "latest"
}
```

---

##  Testing

### Manual Testing Steps

1. **Verify Managed Identity**:
   ```bash
   # On the VM
   curl -H Metadata:true "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://snowflakecomputing.com/session:scope"
   ```

2. **Check Snowflake User**:
   ```sql
   -- In Snowflake
   SHOW USERS LIKE 'WIF_TEST_USER';
   DESC USER WIF_TEST_USER;
   ```

3. **Verify Role Grants**:
   ```sql
   SHOW GRANTS TO USER WIF_TEST_USER;
   SHOW GRANTS TO ROLE WIF_TEST_ROLE;
   ```

### Automated Testing

The test script (`test_snowflake.py`) automatically:
- Obtains an Azure AD token using the managed identity
- Authenticates to Snowflake using WIF
- Executes test queries
- Verifies permissions

---

## 🔧 Troubleshooting

### Common Issues

#### 1. Managed Identity Token Acquisition Failed

**Error**: `Failed to obtain Azure AD token`

**Solutions**:
- Verify the managed identity is assigned to the VM
- Check that the managed identity has the correct permissions
- Ensure the VM can reach Azure AD endpoints

```bash
# Verify managed identity on VM
curl -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2021-02-01" | jq .compute.identity
```

#### 2. Snowflake Connection Failed

**Error**: `WIF Connection Failed: JWT token is invalid`

**Solutions**:
- Verify the Snowflake WIF user exists
- Check that the Azure Application ID matches the managed identity client ID
- Ensure the Azure Tenant ID is correct

```sql
-- In Snowflake, check WIF user configuration
DESC USER WIF_TEST_USER;
```

#### 3. SSH Connection Issues

**Error**: `Connection refused` or `Permission denied`

**Solutions**:
- Verify NSG rules allow SSH from your IP
- Check that the public IP is created (if `enable_public_ip = true`)
- Ensure SSH key is correctly configured

```bash
# Check NSG rules
az network nsg rule list --resource-group rg-snowflake-wif-test --nsg-name snow-wif-test-nsg --output table
```

#### 4. Insufficient Snowflake Privileges

**Error**: `Insufficient privileges to operate on warehouse`

**Solutions**:
- Grant necessary permissions to the WIF role
- Verify warehouse, database, and schema exist

```sql
-- Grant permissions
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE WIF_TEST_ROLE;
GRANT USAGE ON DATABASE TEST_DB TO ROLE WIF_TEST_ROLE;
GRANT USAGE ON SCHEMA TEST_DB.PUBLIC TO ROLE WIF_TEST_ROLE;
```

### Debugging Commands

```bash
# Check cloud-init logs
sudo cat /var/log/cloud-init-output.log

# Verify Python environment
source /opt/snowflake-test/venv/bin/activate
pip list | grep snowflake

# Test Azure identity manually
python3 -c "from azure.identity import ManagedIdentityCredential; print(ManagedIdentityCredential().get_token('https://snowflakecomputing.com/session:scope'))"
```

---

## 🔒 Security Considerations

### Best Practices

1. **Network Security**:
   - Use private subnets when possible
   - Restrict SSH access to specific IP addresses
   - Consider using Azure Bastion instead of public IPs

2. **Identity Management**:
   - Use user-assigned managed identities (not system-assigned)
   - Implement least privilege access in Snowflake
   - Regularly rotate and audit access

3. **Monitoring**:
   - Enable Azure Monitor for VM metrics
   - Configure Snowflake query history monitoring
   - Set up alerts for failed authentication attempts

4. **Compliance**:
   - Ensure all resources are tagged appropriately
   - Document WIF user purpose and ownership
   - Regular access reviews

### Production Recommendations

```hcl
# Production-ready configuration
enable_public_ip           = false  # Use private access
allow_ssh_from_internet    = false
ssh_source_address_prefixes = []    # No direct SSH

# Use Azure Bastion or VPN for access
# Implement network policies
# Enable Azure Security Center
```

---

## 🧹 Cleanup

To remove all resources:

```bash
# Destroy all Terraform-managed resources
terraform destroy

# Verify resources are deleted
az resource list --resource-group rg-snowflake-wif-test
```

**Note**: This will delete:
- Azure VM and all associated resources
- Managed identity
- Snowflake WIF user and role

---

##  Additional Resources

- [Snowflake Workload Identity Federation Documentation](https://docs.snowflake.com/en/user-guide/admin-security-fed-auth-wif)
- [Azure Managed Identities Documentation](https://learn.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/)
- [Terraform Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Terraform Snowflake Provider Documentation](https://registry.terraform.io/providers/Snowflake-Labs/snowflake/latest/docs)

---

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

## License

This project is provided as-is for testing and demonstration purposes.

---

## Support

For issues or questions:
- Open an issue on [GitHub](https://github.com/Snowflake-Applied-Field-Engineering/snowflake-wif-azure-sp/issues)
- Contact the Snowflake Applied Field Engineering team

---

**Note**: This module is designed for testing and demonstration purposes. For production deployments, additional security hardening and compliance measures should be implemented.
