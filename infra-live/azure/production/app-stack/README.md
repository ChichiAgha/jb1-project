# Azure Production App Stack

This stack follows the same live-environment layout as `Plateng-terraform-live`, but targets Azure.

## Provisioned Resources

- resource group
- virtual network
- public and private subnets
- NAT Gateway and public IP
- network security groups
- Application Gateway
- Linux Virtual Machine Scale Set

## Runtime Model

The Application Gateway is public.

The VM Scale Set runs in a private subnet.

Each VM instance bootstraps Docker and runs:

- `taskapp-frontend`
- `taskapp-backend`

The frontend container is published on port `80`, and the backend container stays on the local Docker network.

The backend expects an external PostgreSQL endpoint supplied through `compute.backend_env`.

## Backend State

Configure the AzureRM backend at init time or replace `backend.tf` with your concrete production settings.

Example:

```bash
terraform init \
  -backend-config="resource_group_name=your-tfstate-rg" \
  -backend-config="storage_account_name=yourtfstateaccount" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=production/app-stack/terraform.tfstate"
```

## Example Usage

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```
