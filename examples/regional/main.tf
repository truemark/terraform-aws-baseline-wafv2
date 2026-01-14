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

  # Optional: IP Whitelist - IPs that bypass all WAF rules
  # Uncomment and add your trusted IPs for testing/monitoring
  # ip_whitelist = [
  #   "203.0.113.0/24",    # Example: Internal network
  #   "198.51.100.5/32",   # Example: CI/CD server
  #   "192.0.2.10/32",     # Example: Monitoring system
  # ]

  # Optional: Exclude specific rules that cause false positives
  # excluded_rules = {
  #   "AWSManagedRulesCommonRuleSet" = ["SizeRestrictions_BODY", "GenericRFI_BODY"]
  #   "AWSManagedRulesKnownBadInputsRuleSet" = ["JavaDeserializationRCE"]
  # }

  # Optional: Override specific rule actions (e.g., change block to count)
  # rule_action_overrides = {
  #   "AWSManagedRulesCommonRuleSet" = {
  #     "NoUserAgent_HEADER" = "count"
  #   }
  # }

  # Uncomment the line below to enable log encryption (requires KMS key above)
  # kms_key_id = aws_kms_key.waf_logs.arn

  tags = {
    Environment = "production"
    Project     = "api-security"
    Scope       = "regional"
    ManagedBy   = "terraform"
  }
}
