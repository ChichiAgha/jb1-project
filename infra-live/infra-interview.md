# Infrastructure Interview README

This file is for interview delivery.

It is not the implementation guide. It is the version you use to explain the infrastructure clearly and confidently in an interview.

AWS is first because it is the deeper implementation. Azure is second because it is the compact equivalent.

## AWS

## What I Built

For AWS, I structured the infrastructure in a Terraform live-repo style under:

- [infra-live/aws/development](/home/s10golden/projects/webforx/jb1-project/infra-live/aws/development)
- [infra-live/aws/sandbox](/home/s10golden/projects/webforx/jb1-project/infra-live/aws/sandbox)
- [infra-live/aws/production](/home/s10golden/projects/webforx/jb1-project/infra-live/aws/production)

Each environment is separated into deployable concerns:

- `s3-backend`
- `vpc`
- `ecr`
- `ec2/app`
- `eks`

Each concern has its own Terraform state key.

Example:

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

So the architecture is modular both in code layout and in state management.

## How I Would Explain the AWS Design

Short version:

> I split AWS infrastructure by environment and by concern, so networking, registries, compute, EKS, and Terraform state are all managed independently. That reduces blast radius, makes remote state cleaner, and allows stacks like EKS and EC2 to consume VPC outputs through remote state instead of duplicating networking logic.

More detailed version:

> I used a live-repo structure with separate stacks for S3 backend bootstrap, VPC, ECR, EC2 application infrastructure, and EKS. The VPC, ECR, S3 backend, and EKS stacks mirror shared Git modules from the organization modules repo, while the EC2 app stack uses a local ALB plus ASG module because there was no equivalent shared app module for that shape. Each stack has its own backend state key, so state remains modular and easier to reason about.

## What Resources Exist in AWS

The AWS implementation includes:

- VPC
- public and private subnets across at least 2 AZs
- Internet Gateway
- NAT Gateway with Elastic IP
- route tables and route table associations
- ECR repositories
- security groups
- Application Load Balancer
- target group
- launch template
- Auto Scaling Group
- EKS control plane
- EKS node groups
- optional EKS add-ons through separate modules

## How the AWS Layers Connect

### 1. `s3-backend`

This is the bootstrap layer.

It creates:

- S3 bucket for Terraform state
- DynamoDB table for state locking
- optional replication configuration depending on the shared module behavior

Interview line:

> I bootstrap remote state first, because the rest of the stacks depend on S3 state storage and DynamoDB locking.

### 2. `vpc`

This creates the core network.

It uses the shared VPC module:

- [infra-live/aws/development/vpc/main.tf](/home/s10golden/projects/webforx/jb1-project/infra-live/aws/development/vpc/main.tf:1)

Interview line:

> The VPC stack is the network foundation. It creates public and private subnets across multiple availability zones, internet connectivity for public resources, and NAT-based outbound access for private resources.

### 3. `ecr`

This creates container registries.

Interview line:

> I separated ECR because container registries are lifecycle-independent from networking and compute. That lets me manage image repository policy and retention separately from application hosting.

### 4. `ec2/app`

This stack reads VPC remote state and creates:

- ALB
- ALB security group
- application security group
- target group
- launch template
- Auto Scaling Group

Interview line:

> The compute stack consumes VPC outputs from remote state, puts the load balancer in public subnets, keeps the EC2 instances in private subnets, and attaches them to an Auto Scaling Group behind an ALB target group.

### 5. `eks`

This stack also reads VPC remote state.

It creates:

- EKS control plane
- node groups
- optional add-ons like storage class, metrics server, load balancer controller, cluster autoscaler, and namespaces

Interview line:

> EKS reuses the same VPC foundation through remote state. The control plane and node groups are separated into modules, and optional cluster capabilities are toggled through dedicated add-on modules rather than one large monolithic EKS file.

## Why I Used Remote State

Interview line:

> I used remote state to keep stacks loosely coupled but still connected. The VPC stack exports network IDs, and downstream stacks like EC2 and EKS read those outputs from S3 state rather than duplicating configuration or hardcoding IDs.

## Why I Used Object Variables

Interview line:

> I grouped related Terraform inputs into object variables like `vpc`, `ecr`, `app_stack`, and `eks`. That keeps the interface cleaner than having dozens of flat variables, and it makes environment configuration easier to review and maintain.

## Why the Live Repo Is Thin

Interview line:

> The live repo is intentionally thin. Its job is to define environment-specific inputs, providers, backend config, and stack boundaries. The shared module repo owns the reusable infrastructure logic. That separation is closer to how a platform team would structure Terraform at scale.

## Why One Part Is Local Instead of Git Module

Interview line:

> The ALB plus ASG application layer is local because the shared modules repo did not already contain a module for that exact composition. Instead of forcing a bad fit, I implemented a local module for the project-specific application hosting layer and kept the shared Git module pattern where it already existed.

## How I Would Defend the State Separation

If asked why not one big state:

> One big state would be simpler at first, but it increases blast radius and makes changes riskier. Separating state by concern means I can update ECR without touching VPC state, or update EKS without re-planning the entire infrastructure estate.

## How I Would Defend the EKS Design

If asked why multiple EKS modules:

> I split the EKS stack into control plane, node groups, aws-auth, and add-ons because those parts change at different rates and have different operational concerns. It also makes optional platform components easier to enable or disable cleanly.

## Good AWS Interview Summary

Use this if you need a concise but strong answer:

> On AWS, I built a modular Terraform live structure with separate stacks for backend state, VPC, ECR, EC2 application hosting, and EKS across development, sandbox, and production. The VPC, ECR, S3 backend, and EKS layers mirror shared Git modules, while the EC2 app stack uses a local ALB plus ASG module because that shape was project-specific. Each stack has its own backend state key, downstream stacks consume upstream outputs through remote state, and the network design keeps internet-facing load balancing in public subnets while application compute stays in private subnets.

## Azure

## What I Built

Azure is the compact equivalent and currently lives under:

- [infra-live/azure/production/app-stack](/home/s10golden/projects/webforx/jb1-project/infra-live/azure/production/app-stack)

It uses local modules for:

- resource group
- network
- app stack

That means the live Azure stack is mainly an orchestration layer.

## What Resources Exist in Azure

The Azure implementation includes:

- Resource Group
- VNet
- public and private subnets
- NAT Gateway
- public IP for NAT
- NSGs
- Application Gateway
- Linux VM Scale Set

## How I Would Explain the Azure Design

Short version:

> Azure is the smaller equivalent of the AWS infrastructure. I used one production app stack that composes three local modules for resource group, network, and application infrastructure. The network module creates the VNet, subnets, NAT, and public IP resources, and the app module creates NSGs, Application Gateway, and a VM Scale Set behind it.

More detailed version:

> I kept Azure intentionally smaller than AWS. Instead of reproducing every stack separately, I used a compact production app stack that orchestrates three local modules. The resource group module supports create-or-reuse behavior, the network module provisions VNet and subnet infrastructure plus NAT, and the app module provisions the security layer, Application Gateway, and VM Scale Set. It gives a cloud-equivalent hosting layout without making Azure the main focus of the project.

## How the Azure Layers Connect

### 1. resource group module

This either:

- creates a resource group
- or looks up an existing one

Interview line:

> I made the resource group module flexible enough to support both greenfield creation and integration into an existing Azure environment.

### 2. network module

This creates:

- VNet
- public subnets
- private subnets
- NAT public IP
- NAT Gateway
- subnet associations for NAT

Interview line:

> The network module handles the Azure equivalent of the AWS VPC layer. It separates public and private address space and gives private subnets controlled outbound connectivity through a NAT gateway.

### 3. app module

This creates:

- public and private NSGs
- NSG rules
- subnet-to-NSG associations
- public IP for Application Gateway
- Application Gateway
- Linux VM Scale Set

Interview line:

> The app module separates edge and workload security, places the Application Gateway in the public-facing layer, and attaches the VM Scale Set to the backend pool so traffic flows from the gateway into private compute.

## Why Azure Is Smaller

Interview line:

> AWS is the primary implementation, so Azure is intentionally a compact equivalent rather than a one-to-one duplicate. The goal was to show multi-cloud understanding without diluting the depth of the AWS design.

## Good Azure Interview Summary

Use this if needed:

> On Azure, I built the compact equivalent using a modular production app stack. It composes separate resource group, network, and application modules to provision a VNet, subnet layout, NAT, NSGs, Application Gateway, and a Linux VM Scale Set. The structure is smaller than AWS by design, but it preserves the same core ideas: layered networking, public entry point, private compute, and reusable module composition.

## How to Position Both Together

If asked why both clouds exist:

> AWS is the deep implementation and Azure is the compact equivalent. AWS demonstrates the full live-repo pattern with multiple environments and separate state per concern. Azure demonstrates that I can translate the same infrastructure ideas into another cloud provider without pretending both clouds need identical depth for the same project.

