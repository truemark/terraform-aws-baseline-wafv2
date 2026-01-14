# Terraform module for AWS WAF v2 baseline security configuration
# Supports both CloudFront (CLOUDFRONT scope) and Regional (REGIONAL scope) deployments

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}

locals {
  # Determine if this is a CloudFront or Regional deployment
  is_cloudfront = var.scope == "CLOUDFRONT"
  is_regional   = var.scope == "REGIONAL"

  # Set appropriate aggregate key type based on scope
  rate_limit_aggregate_key = local.is_regional ? "FORWARDED_IP" : "IP"

  # Generate unique names if not provided
  rule_group_name = var.rule_group_name != null ? var.rule_group_name : "SecurityBaselineRuleGroup"
  web_acl_name    = var.web_acl_name != null ? var.web_acl_name : "${local.is_cloudfront ? "CloudFront" : "Regional"}SecurityBaselineWebACL"

  # Log group name based on scope
  log_group_name = "aws-waf-logs-${local.is_cloudfront ? "global" : "regional"}-waf-acl-logs-${random_id.log_suffix.hex}"

  # IP whitelist configuration
  ip_whitelist_enabled = length(var.ip_whitelist) > 0
  ip_whitelist_name    = var.ip_whitelist_name != null ? var.ip_whitelist_name : "${local.web_acl_name}-IPWhitelist"
}

# Generate random suffix for log group names to ensure uniqueness
resource "random_id" "log_suffix" {
  byte_length = 4
}

# IP Whitelist IP Set (only created if IP whitelist is provided)
resource "aws_wafv2_ip_set" "whitelist" {
  count              = local.ip_whitelist_enabled ? 1 : 0
  name               = local.ip_whitelist_name
  scope              = var.scope
  ip_address_version = "IPV4"
  addresses          = var.ip_whitelist
  tags               = var.tags
}


# Custom Rule Group
resource "aws_wafv2_rule_group" "security_baseline" {
  name     = local.rule_group_name
  scope    = var.scope
  capacity = 500

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "SecurityBaselineRuleGroupMetric"
    sampled_requests_enabled   = true
  }

  # URI Country Based Rate Limiting Rule
  rule {
    name     = "UriCountryBased"
    priority = 1

    action {
      dynamic "count" {
        for_each = var.uri_country_action == "count" ? [1] : []
        content {}
      }
      dynamic "block" {
        for_each = var.uri_country_action == "block" ? [1] : []
        content {}
      }
    }

    statement {
      rate_based_statement {
        limit                 = var.uri_country_rule_limit
        aggregate_key_type    = local.rate_limit_aggregate_key
        evaluation_window_sec = 300

        dynamic "forwarded_ip_config" {
          for_each = local.is_regional ? [1] : []
          content {
            header_name       = "X-Forwarded-For"
            fallback_behavior = "NO_MATCH"
          }
        }

        scope_down_statement {
          and_statement {
            statement {
              byte_match_statement {
                search_string = var.search_string
                field_to_match {
                  uri_path {}
                }
                positional_constraint = "EXACTLY"
                text_transformation {
                  priority = 0
                  type     = "NONE"
                }
              }
            }
            statement {
              geo_match_statement {
                country_codes = var.country_codes
              }
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "uri-country-based"
      sampled_requests_enabled   = true
    }
  }

  # Login Rate Limit Rule
  rule {
    name     = "LoginRateLimitRule"
    priority = 0

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit                 = var.rate_based_rule_limit
        aggregate_key_type    = local.rate_limit_aggregate_key
        evaluation_window_sec = 300

        dynamic "forwarded_ip_config" {
          for_each = local.is_regional ? [1] : []
          content {
            header_name       = "X-Forwarded-For"
            fallback_behavior = "NO_MATCH"
          }
        }

        scope_down_statement {
          byte_match_statement {
            search_string = var.search_string
            field_to_match {
              uri_path {}
            }
            positional_constraint = "STARTS_WITH"
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "login-rate-limit-rule"
      sampled_requests_enabled   = true
    }
  }

  tags = var.tags
}

# Web ACL
resource "aws_wafv2_web_acl" "security_baseline" {
  name  = local.web_acl_name
  scope = var.scope

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "globalWebAclMetric"
    sampled_requests_enabled   = true
  }

  # IP Whitelist Rule (highest priority - allows whitelisted IPs to bypass all WAF rules)
  dynamic "rule" {
    for_each = local.ip_whitelist_enabled ? [1] : []
    content {
      name     = "IPWhitelistAllowRule"
      priority = 0

      action {
        allow {}
      }

      statement {
        ip_set_reference_statement {
          arn = aws_wafv2_ip_set.whitelist[0].arn
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "IPWhitelistAllowRuleMetric"
        sampled_requests_enabled   = true
      }
    }
  }

  # AWS Managed Rules - Common Rule Set
  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = local.ip_whitelist_enabled ? 1 : 0

    override_action {
      dynamic "none" {
        for_each = var.mode == "active" ? [1] : []
        content {}
      }
      dynamic "count" {
        for_each = var.mode == "count" ? [1] : []
        content {}
      }
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  # Custom Security Baseline Rule Group
  rule {
    name     = "SecurityBaselineRuleGroup"
    priority = local.ip_whitelist_enabled ? 2 : 1

    override_action {
      dynamic "none" {
        for_each = var.mode == "active" ? [1] : []
        content {}
      }
      dynamic "count" {
        for_each = var.mode == "count" ? [1] : []
        content {}
      }
    }

    statement {
      rule_group_reference_statement {
        arn = aws_wafv2_rule_group.security_baseline.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "SecurityBaselineRuleGroupMetric"
      sampled_requests_enabled   = true
    }
  }

  # AWS Managed Rules - Known Bad Inputs Rule Set
  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = local.ip_whitelist_enabled ? 3 : 2

    override_action {
      dynamic "none" {
        for_each = var.mode == "active" ? [1] : []
        content {}
      }
      dynamic "count" {
        for_each = var.mode == "count" ? [1] : []
        content {}
      }
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesKnownBadInputsRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  # AWS Managed Rules - Anonymous IP List
  rule {
    name     = "AWS-AWSManagedRulesAnonymousIpList"
    priority = local.ip_whitelist_enabled ? 4 : 3

    override_action {
      dynamic "none" {
        for_each = var.mode == "active" ? [1] : []
        content {}
      }
      dynamic "count" {
        for_each = var.mode == "count" ? [1] : []
        content {}
      }
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAnonymousIpList"
        vendor_name = "AWS"

        # Override the HostingProviderIPList rule to count instead of block
        rule_action_override {
          name = "HostingProviderIPList"
          action_to_use {
            count {}
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesAnonymousIpListMetric"
      sampled_requests_enabled   = true
    }
  }

  # AWS Managed Rules - Amazon IP Reputation List
  rule {
    name     = "AWS-AWSManagedRulesAmazonIpReputationList"
    priority = local.ip_whitelist_enabled ? 5 : 4

    override_action {
      dynamic "none" {
        for_each = var.mode == "active" ? [1] : []
        content {}
      }
      dynamic "count" {
        for_each = var.mode == "count" ? [1] : []
        content {}
      }
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesAmazonIpReputationListMetric"
      sampled_requests_enabled   = true
    }
  }

  tags = var.tags
}

# CloudWatch Log Group for WAF logs
resource "aws_cloudwatch_log_group" "waf_log_group" {
  name              = local.log_group_name
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_id
  tags              = var.tags
}

# WAF Logging Configuration
resource "aws_wafv2_web_acl_logging_configuration" "security_baseline" {
  resource_arn            = aws_wafv2_web_acl.security_baseline.arn
  log_destination_configs = [aws_cloudwatch_log_group.waf_log_group.arn]

  depends_on = [aws_cloudwatch_log_group.waf_log_group]
}
