variable "scope" {
  description = "The scope of the WebACL. Valid values are CLOUDFRONT or REGIONAL."
  type        = string
  validation {
    condition     = contains(["CLOUDFRONT", "REGIONAL"], var.scope)
    error_message = "Scope must be either CLOUDFRONT or REGIONAL."
  }
}

variable "mode" {
  description = "The mode of the rule group. To Block or to Count. By default it is set to count."
  type        = string
  default     = "count"
  validation {
    condition     = contains(["count", "active"], var.mode)
    error_message = "Mode must be either 'count' or 'active'."
  }
}

variable "web_acl_name" {
  description = "The name of the WebACL. If not provided, a default name will be generated based on scope."
  type        = string
  default     = null
}

variable "rule_group_name" {
  description = "The name of the rule group. If not provided, defaults to 'SecurityBaselineRuleGroup'."
  type        = string
  default     = null
}

variable "log_retention_days" {
  description = "The number of days log events are kept in CloudWatch Logs. Default is 365 days (1 year)."
  type        = number
  default     = 365
  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653
    ], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch Logs retention period."
  }
}

variable "country_codes" {
  description = "The country codes to match against for geo-blocking rules."
  type        = list(string)
  default     = ["CN", "RU"]
  validation {
    condition     = length(var.country_codes) > 0
    error_message = "At least one country code must be provided."
  }
}

variable "search_string" {
  description = "The string to search for in the request URI path."
  type        = string
  default     = "/api/login"
}

variable "uri_country_rule_limit" {
  description = "The rate limit for country-based URI matching rule (requests per 5-minute window)."
  type        = number
  default     = 200
  validation {
    condition     = var.uri_country_rule_limit >= 100 && var.uri_country_rule_limit <= 2000000000
    error_message = "URI country rule limit must be between 100 and 2,000,000,000."
  }
}

variable "uri_country_action" {
  description = "The action to take on the URI country rule."
  type        = string
  default     = "count"
  validation {
    condition     = contains(["count", "block"], var.uri_country_action)
    error_message = "URI country action must be either 'count' or 'block'."
  }
}

variable "rate_based_rule_limit" {
  description = "The rate limit for the login rate limiting rule (requests per 5-minute window)."
  type        = number
  default     = 300
  validation {
    condition     = var.rate_based_rule_limit >= 100 && var.rate_based_rule_limit <= 2000000000
    error_message = "Rate based rule limit must be between 100 and 2,000,000,000."
  }
}

variable "kms_key_id" {
  description = "The ARN of the KMS Key to use when encrypting log data. If not provided, encryption is disabled."
  type        = string
  default     = null
}

variable "tags" {
  description = "A map of tags to assign to the resources."
  type        = map(string)
  default     = {}
}
