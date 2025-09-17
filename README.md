# AWS WAF v2 Baseline Security Terraform Module

This Terraform module creates a baseline AWS WAF v2 configuration that provides essential security protections for both CloudFront distributions and regional resources (ALB, API Gateway, etc.). The module is based on proven CDK constructs and implements industry best practices for web application security.

## Features

- **Dual Scope Support**: Works with both CloudFront (CLOUDFRONT) and Regional (REGIONAL) deployments
- **Custom Rate Limiting**: Configurable rate limiting rules for login endpoints and country-based restrictions
- **AWS Managed Rules**: Includes multiple AWS managed rule sets for comprehensive protection
- **Geo-blocking**: Country-based blocking with customizable country codes
- **Comprehensive Logging**: CloudWatch logging with configurable retention periods and optional encryption
- **NIST 800-171 Compliance**: Support for log encryption using AWS KMS for compliance requirements
- **Flexible Configuration**: Count or active mode for all rules

## Security Rules Included

### Custom Rules (Rule Group)
1. **URI Country Based Rule**: Rate limiting for specific URI paths from certain countries
2. **Login Rate Limit Rule**: Aggressive rate limiting for login endpoints

### AWS Managed Rules
1. **AWSManagedRulesCommonRuleSet**: Protection against common web vulnerabilities
2. **AWSManagedRulesKnownBadInputsRuleSet**: Blocks known malicious inputs
3. **AWSManagedRulesAnonymousIpList**: Blocks requests from anonymous IP addresses
4. **AWSManagedRulesAmazonIpReputationList**: Blocks requests from IP addresses with poor reputation

## Usage

### CloudFront WAF Example

```hcl
module "cloudfront_waf" {
  source = "path/to/this/module"

  scope                    = "CLOUDFRONT"
  mode                     = "count"  # Use "active" for production
  web_acl_name            = "MyCloudFrontWAF"
  rule_group_name         = "MySecurityRules"
  
  # Custom rule configuration
  search_string           = "/api/login"
  country_codes          = ["CN", "RU", "KP"]
  uri_country_rule_limit = 100
  uri_country_action     = "block"
  rate_based_rule_limit  = 200
  
  # Logging configuration
  log_retention_days = 30
  
  tags = {
    Environment = "production"
    Project     = "web-security"
  }
}

# Associate with CloudFront distribution
resource "aws_cloudfront_distribution" "example" {
  # ... other configuration ...
  
  web_acl_id = module.cloudfront_waf.web_acl_id
}
```

### Regional WAF Example (ALB)

```hcl
module "regional_waf" {
  source = "path/to/this/module"

  scope                    = "REGIONAL"
  mode                     = "active"
  web_acl_name            = "MyRegionalWAF"
  
  # Custom rule configuration
  search_string           = "/auth/login"
  country_codes          = ["CN", "RU"]
  uri_country_rule_limit = 150
  uri_country_action     = "count"
  rate_based_rule_limit  = 300
  
  # Logging configuration
  log_retention_days = 365
  
  tags = {
    Environment = "production"
    Project     = "api-security"
  }
}

# Associate with Application Load Balancer
resource "aws_wafv2_web_acl_association" "alb" {
  resource_arn = aws_lb.example.arn
  web_acl_arn  = module.regional_waf.web_acl_arn
}
```

### NIST 800-171 Compliant Configuration with Encryption

```hcl
# Create a KMS key for log encryption
resource "aws_kms_key" "waf_logs" {
  description             = "KMS key for WAF log encryption"
  deletion_window_in_days = 7
  
  tags = {
    Name        = "waf-logs-encryption-key"
    Environment = "production"
    Compliance  = "NIST-800-171"
  }
}

resource "aws_kms_alias" "waf_logs" {
  name          = "alias/waf-logs-encryption"
  target_key_id = aws_kms_key.waf_logs.key_id
}

module "compliant_waf" {
  source = "path/to/this/module"

  scope                    = "REGIONAL"
  mode                     = "active"
  web_acl_name            = "NIST-Compliant-WAF"
  
  # Custom rule configuration
  search_string           = "/api/login"
  country_codes          = ["CN", "RU", "KP"]
  uri_country_rule_limit = 100
  uri_country_action     = "block"
  rate_based_rule_limit  = 200
  
  # Logging configuration with encryption for NIST 800-171 compliance
  log_retention_days = 365
  kms_key_id        = aws_kms_key.waf_logs.arn
  
  tags = {
    Environment = "production"
    Compliance  = "NIST-800-171"
    Project     = "secure-web-app"
  }
}
```

### Minimal Configuration

```hcl
module "simple_waf" {
  source = "path/to/this/module"

  scope         = "CLOUDFRONT"
  country_codes = ["CN", "RU", "KP"]
  search_string = "/api/login"
  uri_country_rule_limit = 200
  rate_based_rule_limit  = 300
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 5.0 |
| random | n/a |

## Resources Created

- `aws_wafv2_rule_group.security_baseline` - Custom rule group with rate limiting rules
- `aws_wafv2_web_acl.security_baseline` - Main WebACL with all rules
- `aws_cloudwatch_log_group.waf_log_group` - CloudWatch log group for WAF logs
- `aws_wafv2_web_acl_logging_configuration.security_baseline` - Logging configuration
- `random_id.log_suffix` - Random suffix for unique log group names

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| scope | The scope of the WebACL. Valid values are CLOUDFRONT or REGIONAL | `string` | n/a | yes |
| country_codes | The country codes to match against for geo-blocking rules | `list(string)` | n/a | yes |
| search_string | The string to search for in the request URI path | `string` | n/a | yes |
| uri_country_rule_limit | The rate limit for country-based URI matching rule (requests per 5-minute window) | `number` | n/a | yes |
| rate_based_rule_limit | The rate limit for the login rate limiting rule (requests per 5-minute window) | `number` | n/a | yes |
| mode | The mode of the rule group. To Block or to Count | `string` | `"count"` | no |
| web_acl_name | The name of the WebACL | `string` | `null` | no |
| rule_group_name | The name of the rule group | `string` | `null` | no |
| log_retention_days | The number of days log events are kept in CloudWatch Logs | `number` | `365` | no |
| uri_country_action | The action to take on the URI country rule | `string` | `"count"` | no |
| kms_key_id | The ARN of the KMS Key to use when encrypting log data. If not provided, encryption is disabled | `string` | `null` | no |
| tags | A map of tags to assign to the resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| web_acl_arn | The ARN of the WAF WebACL |
| web_acl_id | The ID of the WAF WebACL |
| web_acl_name | The name of the WAF WebACL |
| rule_group_arn | The ARN of the WAF Rule Group |
| rule_group_id | The ID of the WAF Rule Group |
| rule_group_name | The name of the WAF Rule Group |
| log_group_arn | The ARN of the CloudWatch Log Group for WAF logs |
| log_group_name | The name of the CloudWatch Log Group for WAF logs |
| scope | The scope of the WAF deployment (CLOUDFRONT or REGIONAL) |
| mode | The mode of the WAF rules (count or active) |

## Key Differences Between Scopes

### CloudFront (CLOUDFRONT)
- Uses `IP` aggregate key type for rate limiting
- No forwarded IP configuration needed
- Must be deployed in `us-east-1` region
- Can only be associated with CloudFront distributions

### Regional (REGIONAL)
- Uses `FORWARDED_IP` aggregate key type for rate limiting
- Includes forwarded IP configuration for proper client IP detection
- Can be deployed in any AWS region
- Can be associated with ALB, API Gateway, and other regional resources

## Security Considerations

1. **Start with Count Mode**: Always start with `mode = "count"` to observe traffic patterns before switching to `mode = "active"`
2. **Monitor CloudWatch Metrics**: Set up CloudWatch alarms for WAF metrics to detect potential attacks
3. **Regular Review**: Regularly review WAF logs and adjust rules based on legitimate traffic patterns
4. **Rate Limits**: Adjust rate limits based on your application's normal traffic patterns
5. **Country Codes**: Carefully consider which countries to block based on your user base

## Cost Considerations

- WAF charges are based on the number of web ACLs, rules, and requests processed
- CloudWatch Logs incur storage costs based on retention period
- Consider log retention period based on compliance requirements vs. cost

## Migration from CDK

This module provides equivalent functionality to the CDK constructs:
- `CloudFrontSecurityBaselineWebAcl` → Use with `scope = "CLOUDFRONT"`
- `RegionalSecurityBaselineWebAcl` → Use with `scope = "REGIONAL"`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This module is licensed under the MIT License. See LICENSE file for details.
