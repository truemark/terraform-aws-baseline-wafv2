# Example: Regional WAF baseline security configuration
# This example creates a WAF WebACL for regional resources (ALB, API Gateway, etc.)
# Users can then associate this WAF with their regional resources

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Optional: KMS key for log encryption (uncomment for NIST 800-171 compliance)
# resource "aws_kms_key" "waf_logs" {
#   description             = "KMS key for WAF log encryption"
#   deletion_window_in_days = 7
#
#   tags = {
#     Name        = "regional-waf-logs-encryption-key"
#     Environment = "production"
#     Compliance  = "NIST-800-171"
#   }
# }
#
# resource "aws_kms_alias" "waf_logs" {
#   name          = "alias/regional-waf-logs-encryption"
#   target_key_id = aws_kms_key.waf_logs.key_id
# }

# Regional WAF Module
module "regional_waf" {
  source = "../../"

  # Required parameters
  scope                  = "REGIONAL"
  country_codes          = ["CN", "RU", "KP"]
  search_string          = "/auth/login"
  uri_country_rule_limit = 150
  rate_based_rule_limit  = 300

  # Optional parameters
  mode               = "count" # Start with count mode for testing
  web_acl_name       = "RegionalSecurityWAF"
  rule_group_name    = "RegionalSecurityRules"
  uri_country_action = "count"
  log_retention_days = 365

  # Uncomment the line below to enable log encryption (requires KMS key above)
  # kms_key_id = aws_kms_key.waf_logs.arn

  tags = {
    Environment = "production"
    Project     = "api-security"
    Scope       = "regional"
    ManagedBy   = "terraform"
  }
}
