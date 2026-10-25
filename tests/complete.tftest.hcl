# Run only by the nightly integration workflow, against real cloud credentials.
run "apply_minimal" {
  command = apply

  module {
    source = "./examples/minimal"
  }

  assert {
    condition     = output.endpoint != null
    error_message = "Expected the example to expose an invoke URL."
  }
}
