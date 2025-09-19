
# Hammerspoon Project Testing

## Prerequisites

- Install [busted](https://olivinelabs.com/busted/) for unit/integration tests:

  ```sh
  luarocks install busted
  ```

- Install [luacov](https://keplerproject.github.io/luacov/) for coverage:

  ```sh
  luarocks install luacov
  ```

## Running Tests

- Run all tests:

  ```sh
  busted tests
  ```

- Run with coverage:

  ```sh
  busted --coverage tests
  luacov
  cat luacov.report.out
  ```

## Adding More Tests

- Add new test files in the `tests/` directory, e.g. `test_module.lua`.
- Use `describe` and `it` blocks for organizing tests.

## Notes

- Some Hammerspoon-specific APIs may not be testable outside the Hammerspoon environment.
- For best results, mock Hammerspoon APIs or isolate pure Lua logic for testing.
