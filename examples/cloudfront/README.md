# CloudFront WAF Example

This example demonstrates how to use the AWS WAF v2 baseline security module to create a WAF WebACL for CloudFront use. It creates:

- WAF WebACL with baseline security rules (CLOUDFRONT scope)
- Custom rule group with rate limiting and geo-blocking
- CloudWatch logging for WAF events

**Note**: This example only creates the WAF resources. You'll need to associate the WAF with your CloudFront distribution separately.

## Architecture

```
WAF WebACL (CLOUDFRONT scope) → Ready for CloudFront association
```

## Security Features

- **Rate Limiting**: Protects `/api/login` endpoints from brute force attacks
- **Geo-blocking**: Blocks requests from specified countries (CN, RU, KP, IR)
- **AWS Managed Rules**: Comprehensive protection against common web vulnerabilities
- **Logging**: All WAF events are logged to CloudWatch for monitoring

## Usage

1. **Initialize Terraform**:
   ```bash
   terraform init
   ```

2. **Plan the deployment**:
   ```bash
   terraform plan
   ```

3. **Apply the configuration**:
   ```bash
   terraform apply
   ```

4. **Associate with CloudFront**:
   Use the output `web_acl_id` to associate with your CloudFront distribution:
   ```hcl
   resource "aws_cloudfront_distribution" "example" {
     # ... other configuration ...
     web_acl_id = module.cloudfront_waf.web_acl_id
   }
   ```

## Important Notes

- **Region**: This example must be deployed in `us-east-1` region as CloudFront WAF resources must be created there
- **Count Mode**: The WAF is initially configured in "count" mode for testing. Change to "active" mode for production
- **Scope**: This creates a WAF with CLOUDFRONT scope, suitable for CloudFront distributions only
- **Association**: This example only creates the WAF - you need to associate it with your CloudFront distribution separately

## Testing the WAF

After associating the WAF with your CloudFront distribution, you can test the WAF rules:

1. **Normal requests**: Should work fine
   ```bash
   curl https://your-cloudfront-domain.cloudfront.net/
   ```

2. **Rate limiting test**: Make multiple rapid requests to the login endpoint
   ```bash
   for i in {1..10}; do curl https://your-cloudfront-domain.cloudfront.net/api/login; done
   ```

3. **Monitor logs**: Check CloudWatch Logs for WAF events
   ```bash
   aws logs describe-log-groups --log-group-name-prefix aws-waf-logs-global
   ```

## Customization

You can customize the WAF configuration by modifying the module parameters:

- `country_codes`: Add or remove countries to block
- `search_string`: Change the protected endpoint path
- `uri_country_rule_limit`: Adjust rate limiting thresholds
- `mode`: Switch to "active" mode for production

## Clean Up

To destroy all resources:

```bash
terraform destroy
```

## Outputs

- `web_acl_arn`: ARN of the WAF WebACL (use for associations)
- `web_acl_id`: ID of the WAF WebACL (use for CloudFront distributions)
- `web_acl_name`: Name of the WAF WebACL
- `rule_group_arn`: ARN of the custom rule group
- `waf_log_group_name`: CloudWatch log group name for WAF logs

## Association Example

To associate this WAF with a CloudFront distribution:

```hcl
resource "aws_cloudfront_distribution" "example" {
  # ... your CloudFront configuration ...
  
  web_acl_id = module.cloudfront_waf.web_acl_id
  
  # ... rest of configuration ...
}
```
