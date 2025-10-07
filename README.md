
## ❄️ Snowflake Workload Identity Federation (WIF) Test Environment (Azure)

A Terraform module to deploy a test **Azure Virtual Machine (VM)** for testing **Snowflake Workload Identity Federation (WIF)**. This enables secure authentication to Snowflake using an **Azure AD Service Principal**, eliminating the need for password or key-based credentials.

-----

##  Architecture Summary

This module creates the following resources:

### In Azure:

  * An **Azure Virtual Machine (VM)** in a subnet of your choosing.
  * A **Managed Identity (User Assigned)**, which the VM will use to authenticate.
  * An **Azure Active Directory (Azure AD) Service Principal** and **App Registration** corresponding to the Managed Identity. This is the identity that Snowflake will trust.
  * A **Network Security Group (NSG)** with minimal, necessary rules.

### In Snowflake:

  * A database **Role (WIF\_TEST\_ROLE)** with permissions.
  * A **Service User (WIF\_TEST\_USER)** configured with the corresponding Azure AD Service Principal ID to enable **WORKLOAD\_IDENTITY** authentication.
  * Permission grants on a warehouse, database, and schema set by you.

-----

##  Quick Start

### Prerequisites

  * **Terraform** $\ge$ 1.5.0
  * A configured Terraform to **Snowflake connection** (A Snowflake user with appropriate permissions to support Terraform automation). **ACCOUNTADMIN** privileges may also help to confirm resources.
  * **Azure CLI** configured and authenticated with appropriate permissions to create VMs, Managed Identities, and configure Azure AD applications.
  * An existing **Azure Virtual Network (VNet)** and **subnet**.

### Deployment Steps

#### 1\. Configure Variables

Create a `terraform.tfvars` file with your specific values. The critical variables for Azure setup relate to your **Azure Tenant ID** and the **VNet/Subnet** for the VM.

```hcl
# Azure Infrastructure
location                  = "your Azure region, e.g., eastus"
resource_group_name       = "rg-wif-test"
virtual_network_name      = "vnet-your-vnet"
subnet_name               = "subnet-your-subnet"
azure_tenant_id           = "YOUR_AZURE_TENANT_ID" # Needed for configuring Snowflake trust
azure_subscription_id     = "YOUR_AZURE_SUBSCRIPTION_ID"

# Snowflake Provider Authentication (for Terraform)
snowflake_account_name    = "your_account_identifier"
snowflake_username        = "your_terraform_user"
snowflake_role            = "ACCOUNTADMIN"

# WIF Test Resources (to be created in Snowflake)
wif_user_name             = "WIF_TEST_USER"
wif_role_name             = "WIF_TEST_ROLE"

# Optional: Key Pair path if using key pair authentication for Snowflake provider
# snowflake_private_key_path = "<KEY PATH HERE>"
```

#### 2\. Deploy the Infrastructure

Once your access is confirmed and variables are configured, run your Terraform commands to deploy your resources:

```bash
terraform init
terraform plan
terraform apply
```

#### 3\. Connect and Test

Connect to the test instance. You can use **Azure Bastion** (if configured) or connect via **SSH** using the public IP (if a public IP and appropriate NSG rules were created by the module). A common and secure method is using the **Azure CLI `az ssh vm`** command:

> **Note:** The specific connection command will depend on your VM configuration. Assuming the module output includes the VM name:

```bash
# Example to get the VM's private IP/name for connection
VM_NAME=$(terraform output -raw vm_name)

# Use the appropriate secure connection method for your environment, e.g.,
# az ssh vm -n $VM_NAME -g rg-wif-test
```

Once connected to the VM, activate the environment and run the test script. The VM's managed identity will be used by the Python script to obtain a token from Azure AD, which is then presented to Snowflake for authentication.

```bash
sudo su -
# This path is assumed to be configured by the Terraform module for the test script
source /opt/snowflake-test/venv/bin/activate 
python3 /opt/snowflake-test/test_snowflake.py
```

-----
