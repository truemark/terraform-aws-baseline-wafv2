# Regional WAF Example

This example demonstrates how to use the AWS WAF v2 baseline security module to create a WAF WebACL for regional resources. It creates:

- WAF WebACL with baseline security rules (REGIONAL scope)
- Custom rule group with rate limiting and geo-blocking
- CloudWatch logging for WAF events

**Note**: This example only creates the WAF resources. You'll need to associate the WAF with your regional resources (ALB, API Gateway, etc.) separately.

## Architecture

```
WAF WebACL (REGIONAL scope) → Ready for ALB/API Gateway association
```

## Security Features

- **Rate Limiting**: Protects `/auth/login` endpoints from brute force attacks
- **Geo-blocking**: Blocks requests from specified countries (CN, RU, KP)
- **AWS Managed Rules**: Comprehensive protection against common web vulnerabilities
- **Forwarded IP Detection**: Properly handles client IP addresses behind load balancers
- **Logging**: All WAF events are logged to CloudWatch for monitoring

## Usage

1. **Set your preferred region** (optional):
   ```bash
   export TF_VAR_aws_region="us-east-1"
   ```

2. **Initialize Terraform**:
   ```bash
   terraform init
   ```

3. **Plan the deployment**:
   ```bash
   terraform plan
   ```

4. **Apply the configuration**:
   ```bash
   terraform apply
   ```

5. **Associate with your resources**:
   Use the output `web_acl_arn` to associate with your ALB, API Gateway, or other regional resources:
   ```hcl
   resource "aws_wafv2_web_acl_association" "example" {
     resource_arn = aws_lb.example.arn
     web_acl_arn  = module.regional_waf.web_acl_arn
   }
   ```

## Important Notes

- **Region**: This example can be deployed in any AWS region (defaults to us-west-2)
- **Count Mode**: The WAF is initially configured in "count" mode for testing. Change to "active" mode for production
- **Forwarded IP**: Regional WAF uses `FORWARDED_IP` aggregate key type to properly detect client IPs behind load balancers
- **Association**: This example only creates the WAF - you need to associate it with your resources separately

## Testing the WAF

After associating the WAF with your ALB or other resources, you can test the WAF rules:

1. **Normal requests**: Should work fine
   ```bash
   curl http://your-resource-endpoint/
   ```

2. **Rate limiting test**: Make multiple rapid requests to the login endpoint
   ```bash
   for i in {1..10}; do curl http://your-resource-endpoint/auth/login; done
   ```

3. **Monitor logs**: Check CloudWatch Logs for WAF events
   ```bash
   aws logs describe-log-groups --log-group-name-prefix aws-waf-logs-regional
   ```

## Customization

You can customize the deployment by modifying variables:

- `aws_region`: Change the deployment region
- WAF module parameters:
  - `country_codes`: Add or remove countries to block
  - `search_string`: Change the protected endpoint path
  - `uri_country_rule_limit`: Adjust rate limiting thresholds
  - `mode`: Switch to "active" mode for production

## Cost Considerations

This example will incur costs for:
- WAF WebACL and rule evaluations
- CloudWatch Logs storage

Estimated monthly cost: $5-15 USD (varies by region and usage)

## Clean Up

To destroy all resources:

```bash
terraform destroy
```

## Outputs

- `web_acl_arn`: ARN of the WAF WebACL (use for associations)
- `web_acl_id`: ID of the WAF WebACL
- `web_acl_name`: Name of the WAF WebACL
- `rule_group_arn`: ARN of the custom rule group
- `waf_log_group_name`: CloudWatch log group name for WAF logs

## Association Examples

To associate this WAF with an Application Load Balancer:

```hcl
resource "aws_wafv2_web_acl_association" "alb" {
  resource_arn = aws_lb.example.arn
  web_acl_arn  = module.regional_waf.web_acl_arn
}
```

To associate this WAF with an API Gateway:

```hcl
resource "aws_wafv2_web_acl_association" "api_gateway" {
  resource_arn = aws_api_gateway_stage.example.arn
  web_acl_arn  = module.regional_waf.web_acl_arn
}
```

## Production Considerations

Before using in production:

1. **Enable Active Mode**: Change `mode = "active"` in the WAF module
2. **Monitor WAF Metrics**: Set up CloudWatch alarms for WAF metrics
3. **Review Rate Limits**: Adjust rate limits based on your application's traffic patterns
4. **Test Thoroughly**: Test WAF rules in count mode before switching to active mode
5. **Log Analysis**: Regularly review WAF logs to identify false positives
