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

  tags = {
    Environment = "production"
    Project     = "web-security"
    Scope       = "cloudfront"
    ManagedBy   = "terraform"
  }
}
