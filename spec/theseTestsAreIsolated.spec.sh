@spec.importNotFound() {
  # Verify that, except for specs that manually source it, 'import' isn't available in specs
  refute import
  refute import @foo
  expect { import } toFail "import: command not found"
}