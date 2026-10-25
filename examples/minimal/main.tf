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
}

resource "aws_iam_role_policy_attachment" "basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "this" {
  function_name    = "olensys-test-httpapi-fn"
  role             = aws_iam_role.lambda.arn
  runtime          = "python3.12"
  architectures    = ["arm64"]
  handler          = "handler.handler"
  filename         = data.archive_file.handler.output_path
  source_code_hash = data.archive_file.handler.output_base64sha256

  tracing_config {
    mode = "Active"
  }
}

module "this" {
  source = "../../"

  name = "olensys-test-httpapi"
  context = {
    organization = "olensys"
    environment  = "test"
    application  = "httpapi"
    owner        = "platform"
    cost_center  = "eng"
  }

  routes = {
    "GET /health" = { lambda_arn = aws_lambda_function.this.arn, authorization = "NONE" }
  }
}

output "endpoint" {
  description = "Invoke URL of the example API."
  value       = module.this.endpoint
}
