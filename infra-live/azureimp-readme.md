# Azure Implementation README

This file explains the Azure Terraform implementation in plain terms.

Important context first:

- Azure is the **compact equivalent**
- AWS is the deeper implementation
- Azure currently exists only as:
  - [infra-live/azure/production/app-stack](/home/s10golden/projects/webforx/jb1-project/infra-live/azure/production/app-stack)

So this README explains that compact Azure stack and the local Azure modules it uses.

## 1. Big picture

The Azure stack is split into:

- a live stack folder
- local reusable modules

Live stack:

- [infra-live/azure/production/app-stack](/home/s10golden/projects/webforx/jb1-project/infra-live/azure/production/app-stack)

Modules:

- [infra-live/modules/azure/resource-group](/home/s10golden/projects/webforx/jb1-project/infra-live/modules/azure/resource-group)
- [infra-live/modules/azure/network](/home/s10golden/projects/webforx/jb1-project/infra-live/modules/azure/network)
- [infra-live/modules/azure/app-stack](/home/s10golden/projects/webforx/jb1-project/infra-live/modules/azure/app-stack)

This means the live stack mainly does orchestration:

- provider setup
- backend setup
- variable definitions
- module wiring

The raw Azure resources live mostly inside the local modules.

## 2. What the Azure stack creates

This stack creates:

- Resource Group
- VNet
- public and private subnets
- NAT Gateway
- public IP for NAT
- NSGs
- Application Gateway
- VM Scale Set

So Azure is still a valid compact equivalent of the AWS setup.

## 3. Files in the live stack

Files:

- [backend.tf](/home/s10golden/projects/webforx/jb1-project/infra-live/azure/production/app-stack/backend.tf:1)
- [providers.tf](/home/s10golden/projects/webforx/jb1-project/infra-live/azure/production/app-stack/providers.tf:1)
- [variables.tf](/home/s10golden/projects/webforx/jb1-project/infra-live/azure/production/app-stack/variables.tf:1)
- [main.tf](/home/s10golden/projects/webforx/jb1-project/infra-live/azure/production/app-stack/main.tf:1)
- [outputs.tf](/home/s10golden/projects/webforx/jb1-project/infra-live/azure/production/app-stack/outputs.tf:1)

## 4. `backend.tf`

- [infra-live/azure/production/app-stack/backend.tf](/home/s10golden/projects/webforx/jb1-project/infra-live/azure/production/app-stack/backend.tf:1)

```hcl
terraform {
  backend "azurerm" {}
}
```

This means:

- Terraform will store state in Azure remote state
- the backend settings are not hardcoded here
- they are expected to be passed during `terraform init` or via backend config

Why this is useful:

- you avoid committing state location details directly into code
- you can reuse the same code in different environments

## 5. `providers.tf`

- [infra-live/azure/production/app-stack/providers.tf](/home/s10golden/projects/webforx/jb1-project/infra-live/azure/production/app-stack/providers.tf:1)

```hcl
terraform {
  required_version = ">= 1.10.5"
```

This says the Terraform CLI must be at least that version.

Then:

```hcl
required_providers {
  azurerm = {
    source  = "hashicorp/azurerm"
    version = "~> 4.0"
  }
}
```

This says:

- use AzureRM provider
- source it from HashiCorp
- stay in provider major version 4

Then:

```hcl
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}
```

Line by line:

- create Azure provider configuration
- `features {}` is required by AzureRM provider
- `subscription_id` tells Terraform which Azure subscription to use

## 6. `variables.tf`

- [infra-live/azure/production/app-stack/variables.tf](/home/s10golden/projects/webforx/jb1-project/infra-live/azure/production/app-stack/variables.tf:1)

This file uses object variables heavily.

That is good because related settings stay grouped.

### `subscription_id`

```hcl
variable "subscription_id" {
  type      = string
  sensitive = true
}
```

This is the Azure subscription to deploy into.

It is marked sensitive because it is not something you want to casually print in logs.

### `resource_group`

This object contains:

- whether to create a new RG or use an existing one
- the location
- naming prefix
- tags

### `network`

This object contains:

- VNet address space
- public subnets
- private subnets
- which private subnets should get the NAT gateway

### `security`

This object contains:

- allowed inbound CIDRs to the Application Gateway
- application port

### `load_balancer`

This object actually configures the Azure Application Gateway.

It contains:

- SKU name and tier
- capacity
- frontend port
- backend port
- health check path

### `compute`

This object configures the VM Scale Set.

It includes:

- VM size
- instance count
- admin username
- SSH key
- image reference
- zones
- backend app environment variables

## 7. `main.tf`

- [infra-live/azure/production/app-stack/main.tf](/home/s10golden/projects/webforx/jb1-project/infra-live/azure/production/app-stack/main.tf:1)

This file is the orchestration layer.

### locals

```hcl
locals {
  common_tags = merge(var.tags, var.resource_group.tags, {
```

This builds one common tag map.

Meaning:

- start with top-level tags
- merge in resource group tags
- add standard tags like:
  - `Environment`
  - `Stack`
  - `ManagedBy`

This is a good pattern because it keeps tagging consistent.

### resource group module

```hcl
module "resource_group" {
  source = "../../../modules/azure/resource-group"
```

This calls the local resource group module.

Then:

```hcl
  resource_group = var.resource_group
  tags           = local.common_tags
}
```

This passes:

- the RG config object
- the common tags

### network module

```hcl
module "network" {
  source = "../../../modules/azure/network"
```

This calls the local network module.

It receives:

- resource group name
- resource group location
- network object
- tags

So the module can create Azure network resources in the correct RG and region.

### app module

```hcl
module "app" {
  source = "../../../modules/azure/app-stack"
```

This is the main application infrastructure module.

It receives:

- resource group name and location
- public subnet IDs
- private subnet IDs
- public subnet prefixes
- name prefix
- security object
- load balancer object
- compute object
- tags

This module is where most of the actual Azure resources are created.

## 8. `modules/azure/resource-group/main.tf`

- [infra-live/modules/azure/resource-group/main.tf](/home/s10golden/projects/webforx/jb1-project/infra-live/modules/azure/resource-group/main.tf:1)

Important block:

```hcl
resource "azurerm_resource_group" "this" {
  count = var.resource_group.create ? 1 : 0
```

This means:

- if `create = true`, Terraform creates the RG
- if `create = false`, it does not create one

Then:

```hcl
data "azurerm_resource_group" "existing" {
  count = var.resource_group.create ? 0 : 1
```

This is the opposite path:

- if not creating a new RG, look up an existing one

Then locals:

```hcl
locals {
  resource_group_name = ...
```

These locals normalize the two paths into one set of outputs.

In plain terms:

- whether you create or reuse the RG, downstream modules get one consistent RG name and location

## 9. `modules/azure/network/main.tf`

- [infra-live/modules/azure/network/main.tf](/home/s10golden/projects/webforx/jb1-project/infra-live/modules/azure/network/main.tf:1)

### VNet

```hcl
resource "azurerm_virtual_network" "this" {
```

This creates the Azure VNet.

Important lines:

- `name`
- `location`
- `resource_group_name`
- `address_space`

### public subnets

```hcl
resource "azurerm_subnet" "public" {
  for_each = var.network.public_subnets
```

This means:

- loop over all configured public subnets
- create one Azure subnet resource for each

The same pattern is used for private subnets:

```hcl
resource "azurerm_subnet" "private" {
```

### NAT public IP

```hcl
resource "azurerm_public_ip" "nat" {
```

This creates a static public IP for the NAT gateway.

### NAT gateway

```hcl
resource "azurerm_nat_gateway" "this" {
```

This creates the NAT gateway itself.

### NAT association

```hcl
resource "azurerm_nat_gateway_public_ip_association" "this" {
```

This attaches the NAT public IP to the NAT gateway.

Then:

```hcl
resource "azurerm_subnet_nat_gateway_association" "private" {
```

This attaches the NAT gateway to selected private subnets.

So private subnets can get outbound internet access without being public themselves.

## 10. `modules/azure/app-stack/main.tf`

- [infra-live/modules/azure/app-stack/main.tf](/home/s10golden/projects/webforx/jb1-project/infra-live/modules/azure/app-stack/main.tf:1)

This file contains the bulk of the Azure app infrastructure.

### locals

At the top:

```hcl
locals {
  public_subnet_keys  = sort(keys(var.public_subnet_ids))
```

This does some preparation:

- sort subnet keys
- pick one public subnet for Application Gateway
- pick one private subnet for VMSS
- render cloud-init user data

The `custom_data` block uses:

```hcl
templatefile("${path.module}/templates/cloud_init.tftpl", ...)
```

This means:

- build a cloud-init startup script
- inject variables into it
- base64 encode it

### NSGs

Two NSGs are created:

```hcl
resource "azurerm_network_security_group" "public" {
resource "azurerm_network_security_group" "private" {
```

This separation mirrors the AWS idea of separating perimeter and app security.

### NSG rules

Important rules:

- `public_http` allows HTTP into the public side
- `public_gateway_manager` allows Azure Gateway Manager ports
- `private_app` allows the app port from the public subnet prefixes to the private subnet workloads

### subnet associations

```hcl
resource "azurerm_subnet_network_security_group_association" "public" {
resource "azurerm_subnet_network_security_group_association" "private" {
```

These attach NSGs to the actual subnets.

### Application Gateway public IP

```hcl
resource "azurerm_public_ip" "appgw" {
```

This creates the public IP for Application Gateway.

### Application Gateway

```hcl
resource "azurerm_application_gateway" "this" {
```

This is Azure's L7 load balancer equivalent for this stack.

Important nested blocks:

- `sku` defines the Application Gateway tier and capacity
- `gateway_ip_configuration` picks the subnet used by the gateway
- `frontend_port` defines the listening port
- `frontend_ip_configuration` attaches the public IP
- `backend_address_pool` defines the backend pool
- `backend_http_settings` defines backend protocol, port, and path settings
- `probe` defines health checks
- `http_listener` defines the frontend listener
- `request_routing_rule` ties listener to backend pool and settings

In simple terms:

- the gateway receives internet traffic
- it health-checks the backend
- it routes traffic to the VM Scale Set

### VM Scale Set

```hcl
resource "azurerm_linux_virtual_machine_scale_set" "app" {
```

This is Azure's scaling compute layer.

Important lines:

- `sku` sets VM size
- `instances` sets desired number of VMs
- `admin_username` and `admin_ssh_key` configure SSH access
- `custom_data` passes startup script
- `source_image_reference` selects the OS image
- `os_disk` configures the root disk
- `zones` optionally spreads instances across availability zones

The nested network interface block is very important:

```hcl
network_interface {
  ...
  ip_configuration {
    ...
    subnet_id = var.private_subnet_ids[local.private_subnet_key]
    application_gateway_backend_address_pool_ids = [
      local.appgw_backend_pool_id
    ]
  }
}
```

Meaning:

- place the VMSS instances in a private subnet
- register them in the Application Gateway backend pool

That is how the gateway can send traffic to them.

## 11. `outputs.tf`

- [infra-live/azure/production/app-stack/outputs.tf](/home/s10golden/projects/webforx/jb1-project/infra-live/azure/production/app-stack/outputs.tf:1)

Outputs exposed:

- resource group name
- VNet ID
- Application Gateway public IP
- VM Scale Set ID

These are useful because other stacks or operators can reference them.

## 12. Important caveat

Just like the AWS local app module, the Azure app stack includes startup bootstrap assumptions through cloud-init.

So this is not purely "network only".

It also assumes how the application would be started on the VMs.

## 13. How to explain this in an interview

Short version:

> Azure is the compact equivalent of the AWS implementation. I used one production app stack that orchestrates three local modules: resource group, network, and app stack. The network module creates the VNet, subnets, NAT gateway, and public IP. The app module creates NSGs, Application Gateway, and a Linux VM Scale Set wired into the backend pool.

More technical version:

> The Azure stack uses object variables and module composition. The live stack handles provider, backend, tags, and module wiring. The resource-group module supports both create and reuse flows, the network module provisions VNet plus subnet and NAT resources, and the app module provisions subnet-level NSGs, an Application Gateway with health probes and routing rules, and a VMSS attached to the gateway backend pool.

## 14. Mechanical Terraform reading guide

This section explains the Azure Terraform syntax mechanically.

The ideas are the same as AWS, but I’ll anchor them to Azure examples from this repo.

### 14.1 How to read a provider block

Example:

```hcl
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}
```

Mechanical breakdown:

- `provider` is the block type
- `"azurerm"` is the provider name
- `{` opens the block
- `features {}` is a nested block with no inner arguments
- `subscription_id = var.subscription_id` is an argument assignment
- `}` closes the block

Important detail:

```hcl
features {}
```

is still a valid nested block even though it is empty.

It is not meaningless syntax. AzureRM expects it.

### 14.2 How to read a variable block

Example:

```hcl
variable "resource_group" {
  description = "Azure resource group configuration object."
  type = object({
    create      = optional(bool, true)
    name        = optional(string, null)
    location    = string
    name_prefix = string
    tags        = optional(map(string), {})
  })
}
```

Mechanical breakdown:

- `variable` = Terraform variable declaration
- `"resource_group"` = variable name
- `description = ...` = documentation string
- `type = object({ ... })` = variable must be an object with the listed fields

Inside the object type:

- `create = optional(bool, true)` means:
  - field name is `create`
  - field type is `bool`
  - it is optional
  - default value is `true`

- `name = optional(string, null)` means:
  - optional string
  - default is `null`

- `location = string` means required string

### 14.3 How to read a locals block

Example:

```hcl
locals {
  common_tags = merge(var.tags, var.resource_group.tags, {
    Environment = "production"
    Stack       = "${var.resource_group.name_prefix}-app"
    ManagedBy   = "terraform"
  })
}
```

Mechanical breakdown:

- `locals` starts a local values block
- `common_tags` is the local name
- `merge(...)` is a function call
- first argument = `var.tags`
- second argument = `var.resource_group.tags`
- third argument = inline object

Inside the inline object:

- `Environment = "production"`
- `Stack = "${var.resource_group.name_prefix}-app"`
- `ManagedBy = "terraform"`

That whole merged result becomes:

```hcl
local.common_tags
```

### 14.4 How to read a module block

Example:

```hcl
module "network" {
  source                  = "../../../modules/azure/network"
  resource_group_name     = module.resource_group.resource_group_name
  resource_group_location = module.resource_group.resource_group_location
  network                 = var.network
  tags                    = local.common_tags
}
```

Mechanical breakdown:

- `module` = Terraform module block
- `"network"` = local module instance name
- `source = ...` = module location on disk
- each remaining line is an input argument passed into the module

This means:

- call the local network module
- give it the resource group name
- give it the resource group location
- give it the network object variable
- give it tags

### 14.5 How to read a resource block

Example:

```hcl
resource "azurerm_virtual_network" "this" {
```

Mechanical breakdown:

- `resource` = create/manage infrastructure
- `"azurerm_virtual_network"` = Azure resource type
- `"this"` = local name

When you later see:

```hcl
azurerm_virtual_network.this.name
```

that means:

- resource type = `azurerm_virtual_network`
- local name = `this`
- attribute = `name`

### 14.6 How to read `for_each`

Example:

```hcl
resource "azurerm_subnet" "public" {
  for_each = var.network.public_subnets
```

Mechanical breakdown:

- Terraform will loop over every item in `var.network.public_subnets`
- create one `azurerm_subnet.public[...]` instance per entry

Then:

```hcl
name = "${var.network.name_prefix}-${each.key}"
```

means:

- `each.key` is the map key
- use it to build a subnet name

And:

```hcl
address_prefixes = each.value.address_prefixes
```

means:

- `each.value` is the object value for the current subnet entry
- use its `address_prefixes` field

### 14.7 How to read `count`

Example from RG module:

```hcl
count = var.resource_group.create ? 1 : 0
```

Mechanical breakdown:

- condition is `var.resource_group.create`
- if true -> `1`
- if false -> `0`

Terraform meaning:

- `count = 1` => create one resource
- `count = 0` => create none

### 14.8 How to read a data block

Example:

```hcl
data "azurerm_resource_group" "existing" {
  count = var.resource_group.create ? 0 : 1
  name  = var.resource_group.name
}
```

Mechanical breakdown:

- `data` = read existing infrastructure, do not create it
- `"azurerm_resource_group"` = Azure data source type
- `"existing"` = local name
- `name = var.resource_group.name` = lookup key

### 14.9 How to read nested Azure blocks

Example:

```hcl
sku {
  name     = var.load_balancer.sku_name
  tier     = var.load_balancer.sku_tier
  capacity = var.load_balancer.capacity
}
```

Mechanical breakdown:

- `sku` is a nested block
- it belongs to the parent resource
- each line inside sets one field for that nested block

Same pattern for:

- `frontend_port`
- `frontend_ip_configuration`
- `backend_address_pool`
- `backend_http_settings`
- `probe`
- `http_listener`
- `request_routing_rule`

### 14.10 How to read lists

Example:

```hcl
zones = ["1", "2", "3"]
```

Mechanical breakdown:

- `[` starts a list
- each string is an element
- `]` closes the list

Another example:

```hcl
application_gateway_backend_address_pool_ids = [
  local.appgw_backend_pool_id
]
```

This is a single-element list.

### 14.11 How to read object values

Example:

```hcl
tags = {
  Environment = "production"
  Project     = "jb1-project"
}
```

Mechanical breakdown:

- `{` opens an object/map value
- each line is key/value assignment
- `}` closes the object

### 14.12 How to read `templatefile`

Example:

```hcl
templatefile("${path.module}/templates/cloud_init.tftpl", {
  dockerhub_username = var.compute.dockerhub_username
  image_tag          = var.compute.image_tag
})
```

Mechanical breakdown:

- first argument = path to the template file
- second argument = object containing template variables

So Terraform:

1. opens the template file
2. replaces placeholders with these values
3. returns the rendered text

Then `base64encode(...)` wraps it.

### 14.13 How to read resource associations

Example:

```hcl
resource "azurerm_subnet_network_security_group_association" "public" {
  for_each = var.public_subnet_ids

  subnet_id                 = each.value
  network_security_group_id = azurerm_network_security_group.public.id
}
```

Mechanical breakdown:

- this resource creates a relationship between a subnet and an NSG
- `for_each` means do this for each subnet
- `subnet_id = each.value` picks the current subnet ID
- `network_security_group_id = ...` points to the NSG

This is how Terraform models "attach A to B".

### 14.14 How to read a VMSS network block

Example:

```hcl
network_interface {
  name    = "app-nic"
  primary = true

  ip_configuration {
    name      = "app-ip-config"
    primary   = true
    subnet_id = var.private_subnet_ids[local.private_subnet_key]
  }
}
```

Mechanical breakdown:

- `network_interface { ... }` defines NIC settings for the VMSS
- inside it, `ip_configuration { ... }` defines the IP config attached to that NIC
- `subnet_id = ...` tells Azure which subnet the NIC should use

### 14.15 How to read index expressions

Example:

```hcl
var.private_subnet_ids[local.private_subnet_key]
```

Mechanical breakdown:

- `var.private_subnet_ids` is a map
- `[local.private_subnet_key]` accesses one item in that map

So this means:

- look up the subnet ID using the chosen subnet key

### 14.16 How to read outputs

Example:

```hcl
output "vm_scale_set_id" {
  description = "Azure Linux VM Scale Set ID."
  value       = module.app.vm_scale_set_id
}
```

Mechanical breakdown:

- `output` declares a Terraform output
- `"vm_scale_set_id"` is the output name
- `description` explains it
- `value` is the actual expression exported

That exported value can later be:

- printed after apply
- consumed by humans
- consumed by other stacks or tooling

### 14.17 How to mechanically parse any Terraform block

Use this sequence:

1. identify the block type:
   - `resource`
   - `module`
   - `data`
   - `variable`
   - `output`
   - `locals`
   - `provider`

2. identify the labels:
   - resource type and local name
   - module name
   - variable name

3. identify the arguments:
   - lines using `=`

4. identify nested blocks:
   - `sku { ... }`
   - `probe { ... }`
   - `network_interface { ... }`

5. identify references:
   - `var.`
   - `local.`
   - `module.`
   - `data.`
   - resource references like `azurerm_virtual_network.this.id`

6. identify loops or conditions:
   - `for_each`
   - `count`
   - `? :`

That is the mechanical reading method you can use on any Terraform file in this repo.
