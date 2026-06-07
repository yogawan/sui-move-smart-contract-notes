# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Sui Move learning repository for writing and experimenting with Move smart contracts on the Sui blockchain.

## Build & Test Commands

```bash
# Build a Move package (run from the package directory)
sui move build

# Run all tests in a package
sui move test

# Run a specific test function
sui move test --filter <test_name>

# Run tests with more output
sui move test --verbose

# Create a new Move package
sui move new <package_name>

# Verify the package structure / check for errors without building
sui move check
```

## Sui Move Project Structure

Sui Move packages follow this convention:

- `Move.toml` — package manifest (name, version, dependencies, published-at)
- `sources/` — Move source files (`.move` extension)
- `tests/` — test files
- `examples/` — example modules or usage

## Move Language Notes

- Sui Move is an object-centric variant of Move. Objects are the primary unit of state.
- Key Sui-specific types: `Coin<T>`, `Balance<T>`, `UID`, `ID`, `Url`, `Clock`
- Common standard library modules: `sui::coin`, `sui::transfer`, `sui::object`, `sui::tx_context`, `sui::event`
- Entry functions (`entry fun`) are callable from transactions; private functions are internal
- Use `#[test]` annotation for test functions and `#[expected_failure]` for tests that should fail
- The Sui CLI (`sui`) must be installed and on `PATH` for build/test commands
