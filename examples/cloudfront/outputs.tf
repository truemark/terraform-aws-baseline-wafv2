output "web_acl_arn" {
  description = "The ARN of the CloudFront WAF WebACL"
  value       = module.cloudfront_waf.web_acl_arn
}

output "web_acl_id" {
  description = "The ID of the CloudFront WAF WebACL"
  value       = module.cloudfront_waf.web_acl_id
}

output "web_acl_name" {
  description = "The name of the CloudFront WAF WebACL"
  value       = module.cloudfront_waf.web_acl_name
}

output "rule_group_arn" {
  description = "The ARN of the WAF Rule Group"
  value       = module.cloudfront_waf.rule_group_arn
}

output "waf_log_group_name" {
  description = "The name of the CloudWatch Log Group for WAF logs"
  value       = module.cloudfront_waf.log_group_name
}
