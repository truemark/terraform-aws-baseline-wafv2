output "web_acl_arn" {
  description = "The ARN of the WAF WebACL"
  value       = aws_wafv2_web_acl.security_baseline.arn
}

output "web_acl_id" {
  description = "The ID of the WAF WebACL"
  value       = aws_wafv2_web_acl.security_baseline.id
}

output "web_acl_name" {
  description = "The name of the WAF WebACL"
  value       = aws_wafv2_web_acl.security_baseline.name
}

output "rule_group_arn" {
  description = "The ARN of the WAF Rule Group"
  value       = aws_wafv2_rule_group.security_baseline.arn
}

output "rule_group_id" {
  description = "The ID of the WAF Rule Group"
  value       = aws_wafv2_rule_group.security_baseline.id
}

output "rule_group_name" {
  description = "The name of the WAF Rule Group"
  value       = aws_wafv2_rule_group.security_baseline.name
}

output "log_group_arn" {
  description = "The ARN of the CloudWatch Log Group for WAF logs"
  value       = aws_cloudwatch_log_group.waf_log_group.arn
}

output "log_group_name" {
  description = "The name of the CloudWatch Log Group for WAF logs"
  value       = aws_cloudwatch_log_group.waf_log_group.name
}

output "scope" {
  description = "The scope of the WAF deployment (CLOUDFRONT or REGIONAL)"
  value       = var.scope
}

output "mode" {
  description = "The mode of the WAF rules (count or active)"
  value       = var.mode
}

output "ip_whitelist_set_arn" {
  description = "The ARN of the IP whitelist IP set (if enabled)"
  value       = local.ip_whitelist_enabled ? aws_wafv2_ip_set.whitelist[0].arn : null
}

output "ip_whitelist_set_id" {
  description = "The ID of the IP whitelist IP set (if enabled)"
  value       = local.ip_whitelist_enabled ? aws_wafv2_ip_set.whitelist[0].id : null
}

output "ip_whitelist_enabled" {
  description = "Whether IP whitelisting is enabled"
  value       = local.ip_whitelist_enabled
}
