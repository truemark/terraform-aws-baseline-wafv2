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

# Regional WAF Module
module "regional_waf" {
  source = "../../"

  # Required parameters
  scope                    = "REGIONAL"
  country_codes           = ["CN", "RU", "KP"]
  search_string           = "/auth/login"
  uri_country_rule_limit  = 150
  rate_based_rule_limit   = 300

  # Optional parameters
  mode                    = "count"  # Start with count mode for testing
  web_acl_name           = "RegionalSecurityWAF"
  rule_group_name        = "RegionalSecurityRules"
  uri_country_action     = "count"
  log_retention_days     = 365

  tags = {
    Environment = "production"
    Project     = "api-security"
    Scope       = "regional"
    ManagedBy   = "terraform"
  }
}
