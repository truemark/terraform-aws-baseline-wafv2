# Example: CloudFront WAF baseline security configuration
# This example creates a WAF WebACL for CloudFront use
# Users can then associate this WAF with their CloudFront distributions

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# Configure the AWS Provider for us-east-1 (required for CloudFront WAF)
provider "aws" {
  region = "us-east-1"
}

# Optional: KMS key for log encryption (uncomment for NIST 800-171 compliance)
# resource "aws_kms_key" "waf_logs" {
#   description             = "KMS key for WAF log encryption"
#   deletion_window_in_days = 7
#
#   tags = {
#     Name        = "cloudfront-waf-logs-encryption-key"
#     Environment = "production"
#     Compliance  = "NIST-800-171"
#   }
# }
#
# resource "aws_kms_alias" "waf_logs" {
#   name          = "alias/cloudfront-waf-logs-encryption"
#   target_key_id = aws_kms_key.waf_logs.key_id
# }

# CloudFront WAF Module
module "cloudfront_waf" {
  source = "../../"

  # Required parameters
  scope                  = "CLOUDFRONT"
  country_codes          = ["CN", "RU", "KP", "IR"]
  search_string          = "/api/login"
  uri_country_rule_limit = 100
  rate_based_rule_limit  = 200

  # Optional parameters
  mode               = "count" # Start with count mode for testing
  web_acl_name       = "CloudFrontSecurityWAF"
  rule_group_name    = "CloudFrontSecurityRules"
  uri_country_action = "block"
  log_retention_days = 30

  # Uncomment the line below to enable log encryption (requires KMS key above)
  # kms_key_id = aws_kms_key.waf_logs.arn

  tags = {
    Environment = "production"
    Project     = "web-security"
    Scope       = "cloudfront"
    ManagedBy   = "terraform"
  }
}
