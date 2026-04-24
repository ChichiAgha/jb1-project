# AWS Implementation README

This file explains the AWS Terraform implementation in `infra-live` step by step, in plain terms.

It is written for a junior engineer who wants to understand:

1. what each folder is for
2. why the code is split this way
3. what each Terraform block is doing
4. how the AWS resources connect together

## 1. Big picture

The AWS side is organized like a Terraform live repo:

```text
infra-live/aws/
  development/
    s3-backend/
    vpc/
    ecr/
    ec2/app/
    eks/
  sandbox/
    ...
  production/
    ...
```

This means:

- each environment has its own folder
- each concern has its own Terraform stack
- each stack has its own state file

That is why you see separate folders for:

- `s3-backend`
- `vpc`
- `ecr`
- `ec2/app`
- `eks`

This is a good pattern because it keeps state smaller and reduces blast radius.

## 2. Why we split the AWS code this way

We do **not** put everything in one `main.tf`.

Instead:

- `s3-backend` creates the remote state bucket and lock table
- `vpc` creates the network
- `ecr` creates container registries
- `ec2/app` creates the load balancer and Auto Scaling compute layer
- `eks` creates the Kubernetes cluster layer

This separation matters because:

- networking changes are isolated from compute changes
- ECR can be managed without touching VPC
- EKS can read VPC outputs instead of recreating network logic
- remote state can be shared cleanly between stacks

## 3. The run order

For a fresh environment, the normal order is:

1. `s3-backend`
2. `vpc`
3. `ecr`
4. `ec2/app`
5. `eks`

Why?

- `s3-backend` creates the S3 bucket and DynamoDB lock table
- other stacks use those resources in `backend.tf`
- `vpc` must exist before `ec2/app` and `eks`
- `ec2/app` and `eks` read VPC outputs from remote state

## 4. What is mirrored from the reference repo

The following live stacks now mirror the shared modules repo pattern correctly:

- `vpc` -> shared Git module
- `ecr` -> shared Git module
- `s3-backend` -> shared Git module
- `eks` -> shared Git modules

The one exception is:

- `ec2/app`

That stack still uses a local module:

- [infra-live/modules/aws/alb-asg/main.tf](/home/s10golden/projects/webforx/jb1-project/infra-live/modules/aws/alb-asg/main.tf:1)

Reason:

your shared modules repo does not currently contain a single AWS module that already packages:

- ALB
- target group
- launch template
- Auto Scaling Group

So that part is a local project-specific module.

## 5. Folder-by-folder explanation

### 5.1 `s3-backend`

Example files:

- [main.tf](/home/s10golden/projects/webforx/jb1-project/infra-live/aws/development/s3-backend/main.tf:1)
- [providers.tf](/home/s10golden/projects/webforx/jb1-project/infra-live/aws/development/s3-backend/providers.tf:1)
- [variables.tf](/home/s10golden/projects/webforx/jb1-project/infra-live/aws/development/s3-backend/variables.tf:1)
- [outputs.tf](/home/s10golden/projects/webforx/jb1-project/infra-live/aws/development/s3-backend/outputs.tf:1)

Purpose:

- create the Terraform state bucket
- create the DynamoDB lock table
- optionally create replication to a backup region

Important detail:

This stack has **no `backend.tf`**.

Why?

Because this stack creates the backend itself. If you pointed it at an S3 backend before the bucket existed, Terraform would fail.

So this stack is the bootstrap stack.

### 5.2 `vpc`

Example files:

- [backend.tf](/home/s10golden/projects/webforx/jb1-project/infra-live/aws/development/vpc/backend.tf:1)
- [providers.tf](/home/s10golden/projects/webforx/jb1-project/infra-live/aws/development/vpc/providers.tf:1)
- [main.tf](/home/s10golden/projects/webforx/jb1-project/infra-live/aws/development/vpc/main.tf:1)
- [outputs.tf](/home/s10golden/projects/webforx/jb1-project/infra-live/aws/development/vpc/outputs.tf:1)

Purpose:

- create VPC
- create public and private subnets
- create IGW
- create NAT + EIP
- create route tables and associations

These resources are created by the shared module:

```hcl
module "vpc" {
  source = "git::https://git.edusuc.net/WEBFORX/Plateng-terraform-modules.git//aws/vpc?ref=develop"
  vpc    = var.vpc
}
```

That means the live repo is intentionally thin.

The live repo only wires inputs and state.

The shared module contains the raw AWS resources.

### 5.3 `ecr`

Example files:

- [backend.tf](/home/s10golden/projects/webforx/jb1-project/infra-live/aws/development/ecr/backend.tf:1)
- [main.tf](/home/s10golden/projects/webforx/jb1-project/infra-live/aws/development/ecr/main.tf:1)
- [outputs.tf](/home/s10golden/projects/webforx/jb1-project/infra-live/aws/development/ecr/outputs.tf:1)

Purpose:

- create one or more ECR repositories
- configure scan on push
- configure lifecycle policy

Again, the live stack just calls the shared module:

```hcl
module "ecr" {
  source = "git::https://git.edusuc.net/WEBFORX/Plateng-terraform-modules.git//aws/ecr?ref=develop"
  ecr    = var.ecr
}
```

### 5.4 `ec2/app`

Example files:

- [backend.tf](/home/s10golden/projects/webforx/jb1-project/infra-live/aws/development/ec2/app/backend.tf:1)
- [main.tf](/home/s10golden/projects/webforx/jb1-project/infra-live/aws/development/ec2/app/main.tf:1)
- [variables.tf](/home/s10golden/projects/webforx/jb1-project/infra-live/aws/development/ec2/app/variables.tf:1)

Purpose:

- read VPC outputs from remote state
- create ALB
- create target group
- create SGs
- create launch template
- create Auto Scaling Group

This stack uses local module:

```hcl
module "app" {
  source = "../../../../../modules/aws/alb-asg"
}
```

### 5.5 `eks`

Example files:

- [backend.tf](/home/s10golden/projects/webforx/jb1-project/infra-live/aws/development/eks/backend.tf:1)
- [providers.tf](/home/s10golden/projects/webforx/jb1-project/infra-live/aws/development/eks/providers.tf:1)
- [data.tf](/home/s10golden/projects/webforx/jb1-project/infra-live/aws/development/eks/data.tf:1)
- [locals.tf](/home/s10golden/projects/webforx/jb1-project/infra-live/aws/development/eks/locals.tf:1)
- [main.tf](/home/s10golden/projects/webforx/jb1-project/infra-live/aws/development/eks/main.tf:1)
- [outputs.tf](/home/s10golden/projects/webforx/jb1-project/infra-live/aws/development/eks/outputs.tf:1)

Purpose:

- create EKS control plane
- create node groups
- optionally configure aws-auth
- optionally configure cluster add-ons

This one closely mirrors your reference repo.

## 6. Line-by-line explanation of the AWS stack patterns

## 6.1 `backend.tf`

Example:

- [infra-live/aws/development/vpc/backend.tf](/home/s10golden/projects/webforx/jb1-project/infra-live/aws/development/vpc/backend.tf:1)

```hcl
terraform {
  backend "s3" {
    bucket         = "jb1-project-development-tf-state"
    key            = "development/vpc/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "jb1-project-development-tf-state-lock"
    encrypt        = true
  }
}
```

What each line means:

- `terraform {` starts Terraform's own configuration block
- `backend "s3"` says store state in S3
- `bucket` is the S3 bucket name
- `key` is the path inside the bucket for this stack's state file
- `region` is where the S3 bucket lives
- `dynamodb_table` is used for state locking
- `encrypt = true` means Terraform state is encrypted in S3

Why the `key` matters:

```hcl
key = "development/vpc/terraform.tfstate"
```

This keeps VPC state separate from:

- `development/ecr/terraform.tfstate`
- `development/eks/terraform.tfstate`
- `development/ec2/app/terraform.tfstate`

That is exactly the modular live pattern you wanted.

## 6.2 `providers.tf`

Example:

- [infra-live/aws/development/vpc/providers.tf](/home/s10golden/projects/webforx/jb1-project/infra-live/aws/development/vpc/providers.tf:1)

```hcl
terraform {
  required_version = ">= 1.10.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

Line by line:

- `required_version` says Terraform CLI must be at least this version
- `required_providers` lists provider plugins this stack needs
- `aws` means use AWS provider
- `source` tells Terraform where to get it from
- `version = "~> 5.0"` means use AWS provider 5.x

Then:

```hcl
provider "aws" {
  region = var.vpc.aws_region
}
```

This says:

- create an AWS provider configuration
- set the region from the `vpc` object variable

This is good because the region comes from inputs, not hardcoded in many places.

## 6.3 `main.tf` in `vpc`

- [infra-live/aws/development/vpc/main.tf](/home/s10golden/projects/webforx/jb1-project/infra-live/aws/development/vpc/main.tf:1)

```hcl
module "vpc" {
  source = "git::https://git.edusuc.net/WEBFORX/Plateng-terraform-modules.git//aws/vpc?ref=develop"
  vpc    = var.vpc
}
```

Line by line:

- `module "vpc"` declares a reusable Terraform module block
- `source = ...//aws/vpc?ref=develop` says use the `aws/vpc` module from your Git module repo
- `vpc = var.vpc` passes the whole `vpc` object variable into that module

This is why you do not see raw `aws_vpc` code in the live stack.

The live repo delegates real resource creation to the shared module.

## 6.4 `variables.tf` in `vpc`

- [infra-live/aws/development/vpc/variables.tf](/home/s10golden/projects/webforx/jb1-project/infra-live/aws/development/vpc/variables.tf:1)

```hcl
variable "vpc" {
  description = "Development VPC configuration object."
  type = object({
    aws_region           = string
    availability_zones   = list(string)
    cidr_block           = string
    enable_dns_support   = optional(bool, true)
    enable_dns_hostnames = optional(bool, true)
    control_plane_names  = optional(list(string), [])
    enable_nat_gateway   = optional(bool, false)
    nat_gateway_count    = optional(number, 1)
    name_prefix          = string
    tags                 = optional(map(string), {})
  })
}
```

What this means:

- there is one variable called `vpc`
- it is an object, not many loose variables
- that object contains all VPC-related settings

Why this is useful:

- cleaner inputs
- easier reuse
- matches your preferred object-variable style

## 6.5 `outputs.tf` in `vpc`

- [infra-live/aws/development/vpc/outputs.tf](/home/s10golden/projects/webforx/jb1-project/infra-live/aws/development/vpc/outputs.tf:1)

```hcl
output "vpc_id" {
  value = module.vpc.vpc_id
}
```

This exposes the VPC ID to other stacks.

Same idea for:

- `public_subnets`
- `private_subnets`

These outputs are later consumed by:

- `ec2/app`
- `eks`

## 6.6 `main.tf` in `ec2/app`

- [infra-live/aws/development/ec2/app/main.tf](/home/s10golden/projects/webforx/jb1-project/infra-live/aws/development/ec2/app/main.tf:1)

```hcl
data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = var.vpc_remote_state.bucket
    key    = var.vpc_remote_state.key
    region = var.vpc_remote_state.region
  }
}
```

This block means:

- read outputs from another Terraform state file
- specifically, the VPC state file

Why?

Because this app stack needs:

- VPC ID
- public subnet IDs
- private subnet IDs

Then:

```hcl
module "app" {
  source = "../../../../../modules/aws/alb-asg"
```

This means:

- use the local app infrastructure module

Then:

```hcl
  network = {
    name_prefix        = var.app_stack.name_prefix
    vpc_id             = data.terraform_remote_state.vpc.outputs.vpc_id
    public_subnet_ids  = data.terraform_remote_state.vpc.outputs.public_subnets
    private_subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnets
  }
```

This is important.

It maps VPC outputs into the local module's expected input shape.

In plain terms:

- get the VPC ID from the VPC stack
- get public subnets from the VPC stack
- get private subnets from the VPC stack
- pass all of that into the app module

Then:

```hcl
  security      = var.app_stack.security
  load_balancer = var.app_stack.load_balancer
  compute       = var.app_stack.compute
  tags          = var.app_stack.tags
}
```

That passes the rest of the app config into the module.

## 6.7 `modules/aws/alb-asg/main.tf`

This is where the raw AWS resources for the app stack live.

- [infra-live/modules/aws/alb-asg/main.tf](/home/s10golden/projects/webforx/jb1-project/infra-live/modules/aws/alb-asg/main.tf:1)

### AMI lookup

```hcl
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
```

This asks AWS for the latest Amazon Linux AMI.

Then the `filter` narrows it to Amazon Linux 2023 x86_64.

### user_data

```hcl
locals {
  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh.tftpl", {
```

This means:

- build a shell script from a template
- substitute variables into it
- base64-encode it because EC2 launch templates expect that format

### ALB security group

```hcl
resource "aws_security_group" "alb" {
```

This creates the security group for the load balancer.

Ingress rules:

- allow port 80
- allow port 443

Egress rule:

- allow all outbound

### app security group

```hcl
resource "aws_security_group" "app" {
```

This is separate from the ALB SG.

That separation is important.

It means:

- the internet talks to the ALB
- the ALB talks to the app
- the app does not directly accept general internet traffic

This line is the key:

```hcl
security_groups = [aws_security_group.alb.id]
```

It means only the ALB security group is allowed to send traffic to the app port.

### ALB

```hcl
resource "aws_lb" "this" {
```

This creates the Application Load Balancer.

Important fields:

- `load_balancer_type = "application"` means ALB
- `security_groups = [aws_security_group.alb.id]` attaches the ALB SG
- `subnets = var.network.public_subnet_ids` places the ALB in public subnets

### target group

```hcl
resource "aws_lb_target_group" "app" {
```

This defines where the ALB forwards traffic.

Important fields:

- `port` is the application port on the instances
- `target_type = "instance"` means forward to EC2 instances
- `vpc_id` ties it to the VPC

The `health_check` block tells AWS how to decide if instances are healthy.

### listeners

There are three listener resources:

- `http_forward`
- `http_redirect`
- `https`

Logic:

- if no certificate ARN is provided, HTTP forwards directly
- if certificate ARN exists, HTTP redirects to HTTPS
- HTTPS listener forwards to the target group

### IAM role and instance profile

```hcl
resource "aws_iam_role" "app" {
```

This creates an IAM role for the EC2 instances.

Then:

```hcl
resource "aws_iam_role_policy_attachment" "ssm" {
```

This attaches the SSM managed policy so instances can be managed with AWS Systems Manager.

Then:

```hcl
resource "aws_iam_instance_profile" "app" {
```

This wraps the role into a form EC2 can attach to an instance.

### launch template

```hcl
resource "aws_launch_template" "app" {
```

This defines how instances should be launched.

Important lines:

- `image_id` chooses the AMI
- `instance_type` sets instance size
- `key_name` sets SSH key pair
- `user_data` provides boot script

The `block_device_mappings` block sets the root disk:

- gp3 volume
- encrypted
- deleted on termination

The `network_interfaces` block attaches the app SG.

The `metadata_options` block hardens IMDS:

- `http_tokens = "required"` enforces IMDSv2

That is a production-minded setting.

### Auto Scaling Group

```hcl
resource "aws_autoscaling_group" "app" {
```

This creates the ASG.

Important lines:

- `desired_capacity` is how many instances you want normally
- `min_size` is the minimum allowed
- `max_size` is the maximum allowed
- `vpc_zone_identifier = var.network.private_subnet_ids` puts instances in private subnets
- `target_group_arns` attaches instances to the ALB target group
- `health_check_type = "ELB"` means ALB health checks influence replacement

This is the core compute scaling layer.

## 6.8 `eks` stack

The EKS stack is more module-oriented.

Main idea:

- read VPC remote state
- use private subnets
- create cluster
- create node groups
- optionally enable cluster add-ons

### `providers.tf`

- [infra-live/aws/development/eks/providers.tf](/home/s10golden/projects/webforx/jb1-project/infra-live/aws/development/eks/providers.tf:1)

You have:

- `aws`
- `tls`
- `kubernetes`
- `helm`

Why `kubernetes` and `helm` providers are here:

after the control plane is created, Terraform can configure cluster resources and Helm-based add-ons.

### `data.tf`

- [infra-live/aws/development/eks/data.tf](/home/s10golden/projects/webforx/jb1-project/infra-live/aws/development/eks/data.tf:1)

This reads the VPC state:

```hcl
data "terraform_remote_state" "vpc"
```

so EKS can use:

- `private_subnets`
- `vpc_id`

### `locals.tf`

- [infra-live/aws/development/eks/locals.tf](/home/s10golden/projects/webforx/jb1-project/infra-live/aws/development/eks/locals.tf:1)

This builds a common tags map:

```hcl
locals {
  tags = merge({
```

That means:

- start with base tags
- merge in user-provided tags from `var.eks.tags`

### `main.tf`

- [infra-live/aws/development/eks/main.tf](/home/s10golden/projects/webforx/jb1-project/infra-live/aws/development/eks/main.tf:1)

Important module blocks:

- `eks_control_plane`
- `eks_node_group`
- `aws_auth_config`
- `eks_storage_class`
- `eks_cluster_autoscaler`
- `eks_ebs_csi_driver`
- `eks_external_dns`
- `eks_load_balancer_controller`
- `eks_metrics_server`
- `eks_namespaces`

Pattern used repeatedly:

```hcl
count = var.enable_x ? 1 : 0
```

This means:

- create the module only when enabled
- skip it when disabled

That is a clean Terraform feature flag pattern.

## 7. What AWS resources exist in the current implementation

Across the AWS implementation, you now have:

- VPC
- public and private subnets across at least 2 AZs
- Internet Gateway
- NAT Gateway with Elastic IP
- route tables and associations
- ECR
- security groups
- ALB
- target group
- launch template
- Auto Scaling Group
- EKS control plane and node groups

## 8. Important caveat

The `ec2/app` module still includes application bootstrap assumptions via user data.

That means it does not only create infrastructure.

It also assumes how the application is started on EC2.

That is fine if the goal is a runnable app stack, but it is not a pure infra-only stack.

## 9. How to explain this in an interview

Good short answer:

> I structured AWS Terraform as a live repo with separate environment folders and separate state per concern. The VPC, ECR, S3 backend, and EKS stacks mirror shared Git modules, while the app compute stack uses a local ALB plus Auto Scaling module because there was no equivalent shared module for that shape. The VPC stack exposes outputs, and the app and EKS stacks consume them through remote state.

Good technical answer:

> Each deployable concern has its own backend key. The bootstrap stack creates remote state infrastructure, the VPC stack creates network primitives, ECR creates registries, the EC2 app stack reads VPC outputs and provisions ALB plus ASG resources, and the EKS stack reuses the same VPC state and composes cluster add-ons through separate modules.

## 10. Mechanical Terraform reading guide

This section is intentionally more mechanical.

It explains the Terraform syntax itself, including braces, blocks, arguments, labels, maps, objects, and references.

### 10.1 How to read this block

Example:

```hcl
module "vpc" {
  source = "git::https://git.edusuc.net/WEBFORX/Plateng-terraform-modules.git//aws/vpc?ref=develop"
  vpc    = var.vpc
}
```

Mechanical breakdown:

- `module` is the Terraform block type
- `"vpc"` is the block label, meaning the local name of this module instance
- `{` opens the body of the block
- `source = ...` is an argument inside the block
- `vpc = var.vpc` is another argument inside the block
- `}` closes the block

What the braces mean:

- the opening `{` says "everything inside belongs to this block"
- the closing `}` ends that block

### 10.2 How to read assignment lines

Example:

```hcl
region = var.vpc.aws_region
```

Mechanical breakdown:

- `region` is the argument name
- `=` is assignment
- `var.vpc.aws_region` is the value expression

That expression means:

- `var` = Terraform variable namespace
- `.vpc` = variable named `vpc`
- `.aws_region` = field inside the `vpc` object

### 10.3 How to read object types

Example:

```hcl
type = object({
  aws_region         = string
  availability_zones = list(string)
})
```

Mechanical breakdown:

- `object(...)` means a structured object type
- the inner `{ ... }` describes the fields of that object
- `aws_region = string` means that field must be a string
- `availability_zones = list(string)` means that field must be a list of strings

Important distinction:

- braces in `object({ ... })` define a **type schema**
- braces in `vpc = { ... }` define an **actual value**

### 10.4 How to read nested blocks

Example:

```hcl
health_check {
  enabled = true
  path    = var.load_balancer.health_check_path
}
```

Mechanical breakdown:

- `health_check` is a nested block type
- `{` opens that nested block
- `enabled = true` is one argument
- `path = ...` is another argument
- `}` closes the nested block

This is different from:

```hcl
health_check = {
  enabled = true
}
```

That second form would be an argument assigned to an object value.

So:

- `health_check { ... }` = nested Terraform block
- `health_check = { ... }` = argument whose value is an object

### 10.5 How to read lists

Example:

```hcl
public_subnets = ["10.10.1.0/24", "10.10.2.0/24"]
```

Mechanical breakdown:

- `[` starts a list
- `"10.10.1.0/24"` is element 1
- `,` separates elements
- `"10.10.2.0/24"` is element 2
- `]` closes the list

### 10.6 How to read maps and object values

Example:

```hcl
tags = {
  Environment = "development"
  Project     = "jb1-project"
}
```

Mechanical breakdown:

- `tags` is the argument name
- `=` assigns a value
- `{` starts an object/map value
- `Environment = "development"` is one key/value pair
- `Project = "jb1-project"` is another key/value pair
- `}` closes the object/map value

### 10.7 How to read resource blocks

Example:

```hcl
resource "aws_lb" "this" {
```

Mechanical breakdown:

- `resource` = Terraform resource block type
- `"aws_lb"` = resource type from the AWS provider
- `"this"` = local name of this resource instance
- `{` opens the resource body

Later, when you see:

```hcl
aws_lb.this.arn
```

that means:

- resource type = `aws_lb`
- local resource name = `this`
- attribute = `arn`

### 10.8 How to read data blocks

Example:

```hcl
data "terraform_remote_state" "vpc" {
```

Mechanical breakdown:

- `data` means read information rather than create a resource
- `"terraform_remote_state"` is the data source type
- `"vpc"` is the local name

Then:

```hcl
data.terraform_remote_state.vpc.outputs.vpc_id
```

means:

- `data` namespace
- `terraform_remote_state` data source type
- `vpc` named instance
- `outputs` exported outputs from that state
- `vpc_id` specific output value

### 10.9 How to read module outputs

Example:

```hcl
value = module.vpc.vpc_id
```

Mechanical breakdown:

- `module` = module namespace
- `.vpc` = module instance named `vpc`
- `.vpc_id` = output exported by that module

### 10.10 How to read `count`

Example:

```hcl
count = var.enable_metrics_server ? 1 : 0
```

Mechanical breakdown:

- `? :` is the ternary operator
- if `var.enable_metrics_server` is true, result is `1`
- otherwise result is `0`

Terraform interpretation:

- `count = 1` means create one instance
- `count = 0` means create none

### 10.11 How to read `for_each`

Example:

```hcl
for_each = var.public_subnets
```

Mechanical breakdown:

- iterate over every item in `var.public_subnets`
- create one resource instance per item

When you later see:

```hcl
each.key
each.value
```

that means:

- `each.key` = current item key
- `each.value` = current item value

### 10.12 How to read `locals`

Example:

```hcl
locals {
  tags = merge({
    Environment = "development"
  }, var.eks.tags)
}
```

Mechanical breakdown:

- `locals` starts a locals block
- `tags` is a local value name
- `merge(...)` is a function call
- first argument is an inline object
- second argument is `var.eks.tags`

So `local.tags` becomes the merged result.

### 10.13 How to read function calls

Example:

```hcl
base64encode(templatefile("${path.module}/templates/user_data.sh.tftpl", {
```

Mechanical breakdown:

- `templatefile(...)` renders a template
- its first argument is the template path
- its second argument is an object of template variables
- `base64encode(...)` wraps the rendered result

So the output of one function becomes the input to another.

### 10.14 How to read interpolation strings

Example:

```hcl
"${var.network.name_prefix}-alb"
```

Mechanical breakdown:

- `"..."` starts a string
- `${ ... }` means evaluate an expression inside the string
- `var.network.name_prefix` resolves first
- `-alb` is literal text appended after it

If `name_prefix = "taskapp-dev"`, the final string becomes:

```text
taskapp-dev-alb
```

### 10.15 How to read dynamic blocks

Example:

```hcl
dynamic "ingress" {
  for_each = length(var.security.ssh_ingress_cidrs) == 0 ? [] : [1]
```

Mechanical breakdown:

- `dynamic "ingress"` means generate nested `ingress` blocks programmatically
- if there are no SSH CIDRs, use empty list `[]`
- if there are SSH CIDRs, use `[1]`
- `[1]` is just a simple trick to make Terraform create one block

So:

- no SSH CIDRs -> no extra ingress block
- SSH CIDRs exist -> one SSH ingress block is created

### 10.16 How to read `depends_on`

Example:

```hcl
depends_on = [module.eks_node_group]
```

Mechanical breakdown:

- `depends_on` is explicit dependency metadata
- `[ ... ]` is a list
- `module.eks_node_group` is the dependency target

Meaning:

- Terraform should wait for that module before planning/applying this block fully

### 10.17 How to read output blocks

Example:

```hcl
output "vpc_id" {
  value = module.vpc.vpc_id
}
```

Mechanical breakdown:

- `output` declares a value Terraform should expose after apply
- `"vpc_id"` is the output name
- `value = ...` is the expression to expose

That output can then be read:

- by humans
- by remote state
- by other tooling

### 10.18 How to read a whole resource from top to bottom

Example:

```hcl
resource "aws_lb_target_group" "app" {
  name        = "${var.network.name_prefix}-tg"
  port        = var.load_balancer.target_port
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.network.vpc_id

  health_check {
    enabled = true
    path    = var.load_balancer.health_check_path
  }
}
```

Mechanical read:

1. declare a resource
2. resource type is `aws_lb_target_group`
3. local name is `app`
4. set its name
5. set backend target port
6. set protocol
7. set target type
8. attach it to the VPC
9. define nested health check rules
10. close the block

That is the simplest way to mechanically parse Terraform:

1. identify the block type
2. identify the labels
3. identify the arguments
4. identify nested blocks
5. identify references to variables, locals, modules, resources, or data
