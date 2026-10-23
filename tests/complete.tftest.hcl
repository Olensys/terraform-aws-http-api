# Run only by the nightly integration workflow, against real cloud credentials.
run "apply_minimal" {
  command = apply

  variables {
    lambda_arn = "arn:aws:lambda:eu-west-1:123456789012:function:example"
  }

  module {
    source = "./examples/minimal"
  }
}
