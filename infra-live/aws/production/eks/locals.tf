locals {
  tags = merge({
    Environment = "production"
    ManagedBy   = "terraform"
  }, var.eks.tags)
}
