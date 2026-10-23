output "id" {
  description = "ID of the HTTP API. Null when create is false."
  value       = var.create ? module.this.api_id : null

  precondition {
    condition     = !var.create || alltrue([for r in values(var.routes) : r.authorization == "NONE" || r.authorization == "AWS_IAM" || r.authorizer_id != null])
    error_message = "Routes with JWT or CUSTOM authorization require authorizer_id."
  }
}

output "name" {
  description = "Name of the HTTP API. Null when create is false."
  value       = var.create ? var.name : null
}

output "arn" {
  description = "ARN of the HTTP API. Null when create is false."
  value       = var.create ? module.this.api_arn : null
}

output "endpoint" {
  description = "Default invoke URL of the API. Null when create is false."
  value       = var.create ? module.this.api_endpoint : null
}

output "domain_target" {
  description = "Regional target domain name to point a CNAME or alias at for the custom domain. Null without a custom domain or when create is false."
  value       = var.create && var.domain != null ? module.this.domain_name_target_domain_name : null
}

output "domain_hosted_zone_id" {
  description = "Route 53 hosted zone ID of the custom domain endpoint, for alias records. Null without a custom domain or when create is false."
  value       = var.create && var.domain != null ? module.this.domain_name_hosted_zone_id : null
}

output "stage_id" {
  description = "ID of the default stage. Null when create is false."
  value       = var.create ? module.this.stage_id : null
}

output "execution_arn" {
  description = "Execution ARN prefix of the API, for IAM or Lambda permissions. Null when create is false."
  value       = var.create ? module.this.api_execution_arn : null
}

output "access_log_group_name" {
  description = "Name of the CloudWatch log group receiving access logs. Null when create is false."
  value       = var.create ? module.this.stage_access_logs_cloudwatch_log_group_name : null
}

output "route_config" {
  description = "The routes as passed to the API: route key to Lambda ARN and authorization type. Null when create is false."
  value       = var.create ? { for k, r in var.routes : k => { lambda_arn = r.lambda_arn, authorization = r.authorization } } : null
}

output "throttling_settings" {
  description = "Default route throttling applied to the stage. Null when create is false."
  value       = var.create ? { burst = var.throttling.burst, rate = var.throttling.rate } : null
}

output "tags" {
  description = "Tags applied to every taggable resource, with context.extra_tags merged in. Null when create is false."
  value       = var.create ? local.tags : null
}
