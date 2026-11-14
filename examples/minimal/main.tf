terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws     = { source = "hashicorp/aws", version = ">= 6.0, < 7.0" }
    archive = { source = "hashicorp/archive", version = ">= 2.4, < 3.0" }
  }
}

data "archive_file" "handler" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/handler.zip"
}

data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "olensys-test-httpapi-fn"
  assume_role_policy = data.aws_iam_policy_document.assume.json
  tags               = module.naming.tags
}

resource "aws_iam_role_policy_attachment" "basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

#trivy:ignore:AVD-AWS-0066 test fixture; tracing adds nothing to the example
resource "aws_lambda_function" "this" {
  function_name    = "olensys-test-httpapi-fn"
  role             = aws_iam_role.lambda.arn
  runtime          = "python3.12"
  architectures    = ["arm64"]
  handler          = "handler.handler"
  filename         = data.archive_file.handler.output_path
  source_code_hash = data.archive_file.handler.output_base64sha256
  tags             = module.naming.tags

  depends_on = [aws_iam_role_policy_attachment.basic]
}

module "naming" {
  source = "git::https://github.com/Olensys/terraform-null-naming.git?ref=v1.0.1"

  context = local.context
}

locals {
  context = {
    organization = "olensys"
    environment  = "test"
    application  = "httpapi"
    owner        = "platform"
    cost_center  = "eng"
  }
}

module "this" {
  source = "../../"

  name    = module.naming.name
  context = local.context
  tags    = module.naming.tags

  routes = {
    "GET /health" = { lambda_arn = aws_lambda_function.this.arn, authorization = "NONE" }
  }
}

output "endpoint" {
  description = "Invoke URL of the example API."
  value       = module.this.endpoint
}
