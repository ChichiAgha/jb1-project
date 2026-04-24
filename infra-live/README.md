# Infra Live

This directory mirrors the live-environment layout used in `Plateng-terraform-live`.

```text
infra-live/
  aws/
    development/
      s3-backend/
      vpc/
      ec2/
        app/
    sandbox/
      s3-backend/
      vpc/
      ec2/
        app/
    production/
      s3-backend/
      vpc/
      ec2/
        app/
  azure/
    production/
      app-stack/
  modules/
```

AWS is separated by environment and concern:

- `s3-backend`: remote state infrastructure
- `ecr`: container registries
- `vpc`: network layer
- `ec2/app`: ALB, target group, launch template, Auto Scaling Group

Azure remains the compact equivalent.

Inputs are grouped into object variables rather than many flat variables.
