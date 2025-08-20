# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-01-20

### Added
- Initial release of AWS WAF v2 Baseline Security Terraform Module
- Support for both CloudFront (CLOUDFRONT) and Regional (REGIONAL) scopes
- Custom rule group with URI country-based rate limiting and login rate limiting
- Integration with AWS managed rule sets:
  - AWSManagedRulesCommonRuleSet
  - AWSManagedRulesKnownBadInputsRuleSet
  - AWSManagedRulesAnonymousIpList
  - AWSManagedRulesAmazonIpReputationList
- CloudWatch logging configuration with configurable retention periods
- Comprehensive examples for CloudFront and Regional deployments
- Full documentation with usage examples and best practices
- Support for count and active modes
- Configurable geo-blocking with country codes
- Rate limiting with configurable thresholds
- Proper forwarded IP handling for regional deployments
- Resource tagging support

### Features
- **Dual Scope Support**: Single module works for both CloudFront and Regional resources
- **Security Best Practices**: Implements industry-standard WAF rules and configurations
- **Flexible Configuration**: Extensive customization options for different use cases
- **Production Ready**: Includes logging, monitoring, and proper resource management
- **Complete Examples**: Working examples with CloudFront and ALB deployments
