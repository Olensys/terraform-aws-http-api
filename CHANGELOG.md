# Changelog

## [1.2.0](https://github.com/Olensys/terraform-aws-http-api/compare/v1.1.2...v1.2.0) (2026-10-26)


### Features

* configurable integration timeout ([#8](https://github.com/Olensys/terraform-aws-http-api/issues/8)) ([eecd33e](https://github.com/Olensys/terraform-aws-http-api/commit/eecd33e7fec9d041d62577c896b6c9587b7308f3))


### Bug Fixes

* **examples:** provision the example Lambda instead of requiring an ARN ([#5](https://github.com/Olensys/terraform-aws-http-api/issues/5)) ([0c2b0da](https://github.com/Olensys/terraform-aws-http-api/commit/0c2b0daed677eecbec2be7d5cf5f1ab7e63dbf7b))

## [1.1.2](https://github.com/Olensys/terraform-aws-http-api/compare/v1.1.1...v1.1.2) (2026-10-24)


### Bug Fixes

* **examples:** unique application slug so concurrent integration runs do not collide ([#3](https://github.com/Olensys/terraform-aws-http-api/issues/3)) ([66a8607](https://github.com/Olensys/terraform-aws-http-api/commit/66a8607b378a5dbd855ab71289cb54f635de9b58))

## [1.1.1](https://github.com/Olensys/terraform-aws-http-api/compare/v1.1.0...v1.1.1) (2026-10-24)


### Bug Fixes

* run integration on change and weekly instead of nightly ([3326717](https://github.com/Olensys/terraform-aws-http-api/commit/33267172616f99e74269f3c18f589d489664aae8))

## 1.1.0

### Behaviour changes

- Every route in `routes` must now set `authorization` explicitly (`NONE`, `AWS_IAM`, `JWT` or `CUSTOM`); the previous default of `NONE` is gone. Callers must add `authorization = "NONE"` to each route that should stay public.

### Fixes

- `authorization` is validated per route; a missing or unknown value fails `var.routes`.

### Tests

- `test_authorization_required` and `test_authorization_enum_validation` replace the assertion of the old `NONE` default.

### Docs

- README Opinions state that `NONE` is an opt-in; Usage shows the naming module.

## 1.0.0

- HTTP API (protocol v2) with Lambda proxy routes, per-route invoke permissions, JSON access logs, default throttling, optional CORS and optional custom domain (DNS left to the caller).
