locals {
  tags = merge(var.context.extra_tags, var.tags)

  routes = var.create ? var.routes : {}

  access_log_format = jsonencode({
    requestId               = "$context.requestId"
    ip                      = "$context.identity.sourceIp"
    requestTime             = "$context.requestTime"
    httpMethod              = "$context.httpMethod"
    routeKey                = "$context.routeKey"
    status                  = "$context.status"
    protocol                = "$context.protocol"
    responseLength          = "$context.responseLength"
    integrationErrorMessage = "$context.integrationErrorMessage"
  })
}

module "this" {
  source  = "terraform-aws-modules/apigateway-v2/aws"
  version = "6.1.1"

  create = var.create
  name   = var.name

  protocol_type = "HTTP"

  routes = {
    for key, route in local.routes : key => {
      authorization_type = route.authorization
      authorizer_id      = route.authorizer_id
      integration = {
        uri                    = route.lambda_arn
        payload_format_version = "2.0"
        timeout_milliseconds   = var.integration_timeout_ms
      }
    }
  }

  cors_configuration = var.cors == null ? null : {
    allow_origins = var.cors.allow_origins
    allow_methods = var.cors.allow_methods
    allow_headers = var.cors.allow_headers
  }

  create_domain_name          = var.create && var.domain != null
  domain_name                 = var.domain == null ? "" : var.domain.name
  domain_name_certificate_arn = var.domain == null ? null : var.domain.certificate_arn
  create_certificate          = false
  create_domain_records       = false

  stage_access_log_settings = {
    create_log_group            = true
    log_group_retention_in_days = var.log_retention_days
    format                      = local.access_log_format
  }

  stage_default_route_settings = {
    throttling_burst_limit   = var.throttling.burst
    throttling_rate_limit    = var.throttling.rate
    detailed_metrics_enabled = true
    data_trace_enabled       = false
  }

  tags = local.tags
}

# The upstream module wires the integrations but does not authorise API Gateway
# to invoke the functions, so each route gets its own invoke permission.
resource "aws_lambda_permission" "routes" {
  for_each = local.routes

  statement_id  = "AllowHttpApi-${substr(md5("${var.name}/${each.key}"), 0, 16)}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.lambda_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.this.api_execution_arn}/*/*"
}
