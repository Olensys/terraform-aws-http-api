# Changelog

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
