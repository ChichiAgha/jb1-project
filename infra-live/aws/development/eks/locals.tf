locals {
  tags = merge({
    Environment = "development"
    ManagedBy   = "terraform"
  }, var.eks.tags)
}
