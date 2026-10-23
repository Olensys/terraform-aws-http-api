variable "name" {
  description = "Resource name. Lowercase letters, digits and hyphens."
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]{1,128}$", var.name))
    error_message = "name must match ^[a-z0-9-]{1,128}$."
  }
}

variable "context" {
  description = "Deployment context used for naming, tagging and environment-dependent defaults."
  type = object({
    organization = string
    environment  = string
    application  = string
    component    = optional(string)
    owner        = string
    cost_center  = string
    extra_tags   = optional(map(string), {})
  })
  validation {
    condition     = contains(["dev", "staging", "prod", "test", "shared"], var.context.environment)
    error_message = "context.environment must be one of dev, staging, prod, test, shared."
  }
}

variable "create" {
  description = "Whether to create any resources. Set false to create nothing."
  type        = bool
  default     = true
}

variable "routes" {
  description = "Routes keyed by route key, for example \"GET /health\" or \"$default\". Each route proxies to a Lambda function (payload format 2.0). authorization is required on every route and is the API Gateway authorization type (NONE, JWT, AWS_IAM or CUSTOM); authorizer_id is required for JWT and CUSTOM."
  type = map(object({
    lambda_arn    = string
    authorization = optional(string)
    authorizer_id = optional(string)
  }))
  validation {
    condition     = alltrue([for k in keys(var.routes) : can(regex("^(GET|POST|PUT|PATCH|DELETE|HEAD|OPTIONS|ANY|\\$default) /", k)) || k == "$default"])
    error_message = "Route keys must look like \"GET /path\" with method GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS or ANY, or be \"$default\"."
  }
  validation {
    condition     = alltrue([for r in values(var.routes) : r.authorization != null && contains(["NONE", "JWT", "AWS_IAM", "CUSTOM"], r.authorization)])
    error_message = "Every route must set authorization explicitly, one of NONE, JWT, AWS_IAM, CUSTOM."
  }
}

variable "domain" {
  description = "Optional custom domain: name and the ARN of an ACM certificate in the API's region. DNS records are the caller's job (see domain_target and domain_hosted_zone_id outputs)."
  type = object({
    name            = string
    certificate_arn = string
  })
  default = null
}

variable "cors" {
  description = "Optional CORS configuration. Null leaves CORS off."
  type = object({
    allow_origins = list(string)
    allow_methods = optional(list(string), ["GET", "POST", "OPTIONS"])
    allow_headers = optional(list(string), ["content-type", "authorization"])
  })
  default = null
}

variable "throttling" {
  description = "Default stage throttling applied to every route: burst limit and steady-state requests per second."
  type = object({
    burst = optional(number, 100)
    rate  = optional(number, 50)
  })
  default = {}
  validation {
    condition     = var.throttling.burst >= 0 && var.throttling.rate >= 0
    error_message = "throttling burst and rate must be zero or greater."
  }
}

variable "log_retention_days" {
  description = "Retention in days of the access log group."
  type        = number
  default     = 30
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.log_retention_days)
    error_message = "log_retention_days must be a value CloudWatch Logs accepts (for example 7, 14, 30, 90, 365)."
  }
}

variable "tags" {
  description = "Tags merged onto every taggable resource, applied last."
  type        = map(string)
  default     = {}
}
