terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 6.0, < 7.0" }
  }
}

variable "lambda_arn" {
  description = "ARN of the Lambda function that serves GET /health."
  type        = string
}

module "this" {
  source = "../../"

  name = "olensys-test-httpapi"
  context = {
    organization = "olensys"
    environment  = "dev"
    application  = "httpapi"
    owner        = "platform"
    cost_center  = "eng"
  }

  routes = {
    "GET /health" = { lambda_arn = var.lambda_arn, authorization = "NONE" }
  }
}

output "endpoint" {
  description = "Invoke URL of the example API."
  value       = module.this.endpoint
}
