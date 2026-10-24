# terraform-aws-http-api

API Gateway HTTP API with Lambda proxy routes, access logging, throttling, CORS and an optional custom domain

## Opinions

- Every route states its `authorization` explicitly; `NONE` is an opt-in.
- HTTP API (`protocol_type = "HTTP"`), not REST. Lambda proxy integrations use payload format 2.0 with a 12 second integration timeout.
- Each route gets its own `aws_lambda_permission` for `apigateway.amazonaws.com`, scoped to this API's execution ARN.
- Access logging is always on, as one JSON line per request (request id, source IP, time, method, route key, status, protocol, response length, integration error message) in a log group with `log_retention_days` retention (default 30).
- Default route throttling is burst 100 and rate 50, with detailed metrics enabled. Per-field overrides via `throttling`.
- Data trace logging is off, so request and response bodies are never logged.
- DNS is the consumer's job: the module never creates DNS records or certificates. Use `domain_target` and `domain_hosted_zone_id` with your DNS module.
- The custom domain certificate must be an ACM certificate in the same region as the API.
- With a custom domain, the default `execute-api` endpoint is disabled by the upstream module.

## Usage

```hcl
module "naming" {
  source  = "git::https://github.com/Olensys/terraform-null-naming.git?ref=v1.0.1"
  context = var.context
}

module "http_api" {
  source  = "git::https://github.com/Olensys/terraform-aws-http-api.git?ref=v1.1.0"
  name    = module.naming.name
  context = var.context

  routes = {
    "GET /health" = { lambda_arn = "arn:aws:lambda:eu-west-1:123456789012:function:health", authorization = "NONE" }
  }

  tags = module.naming.tags
}
```

## Integration test

The nightly integration run applies `examples/minimal` and needs the repository variable `TF_VAR_lambda_arn` set to the ARN of an existing Lambda function.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0, < 7.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0, < 7.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_this"></a> [this](#module\_this) | terraform-aws-modules/apigateway-v2/aws | 6.1.1 |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_lambda_permission.routes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_context"></a> [context](#input\_context) | Deployment context used for naming, tagging and environment-dependent defaults. | <pre>object({<br/>    organization = string<br/>    environment  = string<br/>    application  = string<br/>    component    = optional(string)<br/>    owner        = string<br/>    cost_center  = string<br/>    extra_tags   = optional(map(string), {})<br/>  })</pre> | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Resource name. Lowercase letters, digits and hyphens. | `string` | n/a | yes |
| <a name="input_routes"></a> [routes](#input\_routes) | Routes keyed by route key, for example "GET /health" or "$default". Each route proxies to a Lambda function (payload format 2.0). authorization is required on every route and is the API Gateway authorization type (NONE, JWT, AWS\_IAM or CUSTOM); authorizer\_id is required for JWT and CUSTOM. | <pre>map(object({<br/>    lambda_arn    = string<br/>    authorization = optional(string)<br/>    authorizer_id = optional(string)<br/>  }))</pre> | n/a | yes |
| <a name="input_cors"></a> [cors](#input\_cors) | Optional CORS configuration. Null leaves CORS off. | <pre>object({<br/>    allow_origins = list(string)<br/>    allow_methods = optional(list(string), ["GET", "POST", "OPTIONS"])<br/>    allow_headers = optional(list(string), ["content-type", "authorization"])<br/>  })</pre> | `null` | no |
| <a name="input_create"></a> [create](#input\_create) | Whether to create any resources. Set false to create nothing. | `bool` | `true` | no |
| <a name="input_domain"></a> [domain](#input\_domain) | Optional custom domain: name and the ARN of an ACM certificate in the API's region. DNS records are the caller's job (see domain\_target and domain\_hosted\_zone\_id outputs). | <pre>object({<br/>    name            = string<br/>    certificate_arn = string<br/>  })</pre> | `null` | no |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | Retention in days of the access log group. | `number` | `30` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags merged onto every taggable resource, applied last. | `map(string)` | `{}` | no |
| <a name="input_throttling"></a> [throttling](#input\_throttling) | Default stage throttling applied to every route: burst limit and steady-state requests per second. | <pre>object({<br/>    burst = optional(number, 100)<br/>    rate  = optional(number, 50)<br/>  })</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_access_log_group_name"></a> [access\_log\_group\_name](#output\_access\_log\_group\_name) | Name of the CloudWatch log group receiving access logs. Null when create is false. |
| <a name="output_arn"></a> [arn](#output\_arn) | ARN of the HTTP API. Null when create is false. |
| <a name="output_domain_hosted_zone_id"></a> [domain\_hosted\_zone\_id](#output\_domain\_hosted\_zone\_id) | Route 53 hosted zone ID of the custom domain endpoint, for alias records. Null without a custom domain or when create is false. |
| <a name="output_domain_target"></a> [domain\_target](#output\_domain\_target) | Regional target domain name to point a CNAME or alias at for the custom domain. Null without a custom domain or when create is false. |
| <a name="output_endpoint"></a> [endpoint](#output\_endpoint) | Default invoke URL of the API. Null when create is false. |
| <a name="output_execution_arn"></a> [execution\_arn](#output\_execution\_arn) | Execution ARN prefix of the API, for IAM or Lambda permissions. Null when create is false. |
| <a name="output_id"></a> [id](#output\_id) | ID of the HTTP API. Null when create is false. |
| <a name="output_name"></a> [name](#output\_name) | Name of the HTTP API. Null when create is false. |
| <a name="output_route_config"></a> [route\_config](#output\_route\_config) | The routes as passed to the API: route key to Lambda ARN and authorization type. Null when create is false. |
| <a name="output_stage_id"></a> [stage\_id](#output\_stage\_id) | ID of the default stage. Null when create is false. |
| <a name="output_tags"></a> [tags](#output\_tags) | Tags applied to every taggable resource, with context.extra\_tags merged in. Null when create is false. |
| <a name="output_throttling_settings"></a> [throttling\_settings](#output\_throttling\_settings) | Default route throttling applied to the stage. Null when create is false. |
<!-- END_TF_DOCS -->
