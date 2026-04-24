locals {
  tags = merge({
    Environment = "sandbox"
    ManagedBy   = "terraform"
  }, var.eks.tags)
}
