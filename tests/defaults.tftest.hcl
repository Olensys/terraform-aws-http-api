mock_provider "aws" {
  mock_resource "aws_apigatewayv2_api" {
    defaults = {
      arn           = "arn:aws:apigateway:eu-west-1::/apis/abc123"
      execution_arn = "arn:aws:execute-api:eu-west-1:123456789012:abc123"
    }
  }

  mock_resource "aws_cloudwatch_log_group" {
    defaults = {
      arn = "arn:aws:logs:eu-west-1:123456789012:log-group:/aws/apigateway/example/default"
    }
  }

  mock_data "aws_partition" {
    defaults = {
      partition  = "aws"
      dns_suffix = "amazonaws.com"
    }
  }
}

variables {
  context = {
    organization = "olensys"
    environment  = "test"
    application  = "example"
    owner        = "platform"
    cost_center  = "eng"
  }
  name = "example"
  routes = {
    "GET /health"  = { lambda_arn = "arn:aws:lambda:eu-west-1:123456789012:function:health", authorization = "NONE" }
    "POST /orders" = { lambda_arn = "arn:aws:lambda:eu-west-1:123456789012:function:orders", authorization = "NONE" }
    "$default"     = { lambda_arn = "arn:aws:lambda:eu-west-1:123456789012:function:fallback", authorization = "NONE" }
  }
}

run "test_route_per_key_with_permission" {
  command = plan

  assert {
    condition     = length(output.route_config) == 3
    error_message = "Expected one route_config entry per routes key."
  }

  assert {
    condition     = length(aws_lambda_permission.routes) == 3
    error_message = "Expected one aws_lambda_permission per route."
  }

  assert {
    condition     = alltrue([for p in aws_lambda_permission.routes : p.principal == "apigateway.amazonaws.com"])
    error_message = "Permissions must be granted to the API Gateway principal."
  }
}

run "test_access_logs_on" {
  command = plan

  variables {
    log_retention_days = 14
  }

  # SMOKE: asserts only that the access log group name is exposed (known at plan); the JSON format and retention value live in the upstream child module and are proven by tests/complete.tftest.hcl.
  assert {
    condition     = output.access_log_group_name != null
    error_message = "Access logging must be enabled with a log group."
  }
}

run "test_throttling_defaults" {
  command = plan

  # SMOKE: asserts the throttling values this module passes to the stage; the applied stage settings live in the upstream child module and are proven by tests/complete.tftest.hcl.
  assert {
    condition     = output.throttling_settings.burst == 100 && output.throttling_settings.rate == 50
    error_message = "Throttling must default to burst 100 and rate 50."
  }
}

run "test_throttling_override" {
  command = plan

  variables {
    throttling = { burst = 10 }
  }

  # SMOKE: asserts the values passed to the stage only.
  assert {
    condition     = output.throttling_settings.burst == 10 && output.throttling_settings.rate == 50
    error_message = "Throttling override must apply per field."
  }
}

run "test_create_false_plans_nothing" {
  command = plan

  variables {
    create = false
  }

  assert {
    condition     = length(aws_lambda_permission.routes) == 0
    error_message = "No permissions may be planned when create is false."
  }

  assert {
    condition = alltrue([
      output.id == null, output.name == null, output.arn == null, output.endpoint == null,
      output.domain_target == null, output.domain_hosted_zone_id == null, output.stage_id == null,
      output.execution_arn == null, output.tags == null, output.route_config == null,
      output.throttling_settings == null, output.access_log_group_name == null,
    ])
    error_message = "Every output must be null when create is false."
  }
}

run "test_tags_contract" {
  command = plan

  variables {
    tags = { Owner = "x" }
    context = {
      organization = "olensys"
      environment  = "test"
      application  = "example"
      owner        = "platform"
      cost_center  = "eng"
      extra_tags   = { Owner = "y", Team = "z" }
    }
  }

  assert {
    condition     = output.tags.Owner == "x"
    error_message = "var.tags must win over context.extra_tags."
  }

  assert {
    condition     = output.tags.Team == "z"
    error_message = "context.extra_tags must be merged."
  }
}

run "test_route_key_validation" {
  command = plan

  variables {
    routes = { "FETCH /x" = { lambda_arn = "arn:aws:lambda:eu-west-1:123456789012:function:x", authorization = "NONE" } }
  }

  expect_failures = [var.routes]
}

run "test_name_length_validation" {
  command = plan

  variables {
    name = join("", [for i in range(129) : "a"])
  }

  expect_failures = [var.name]
}

run "test_domain_outputs_null_without_domain" {
  command = plan

  assert {
    condition     = output.domain_target == null && output.domain_hosted_zone_id == null
    error_message = "Domain outputs must be null when no domain is configured."
  }
}

run "test_authorizer_required_for_jwt" {
  command = plan

  variables {
    routes = { "GET /x" = { lambda_arn = "arn:aws:lambda:eu-west-1:123456789012:function:x", authorization = "JWT" } }
  }

  expect_failures = [output.id]
}

run "test_authorization_required" {
  command = plan

  variables {
    routes = { "GET /x" = { lambda_arn = "arn:aws:lambda:eu-west-1:123456789012:function:x" } }
  }

  expect_failures = [var.routes]
}

run "test_authorization_enum_validation" {
  command = plan

  variables {
    routes = { "GET /x" = { lambda_arn = "arn:aws:lambda:eu-west-1:123456789012:function:x", authorization = "OPEN" } }
  }

  expect_failures = [var.routes]
}
