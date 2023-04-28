# Contributing to Project F

Project F welcomes contributions from beginners and experts alike. We have a few simple policies to ensure new designs are compatible with the project goals. This document is a draft; we will expand it as needed.

## Simple

Our designs are self-contained and simple to understand. Complex or overly clever designs are unlikely to be accepted.

## Universal

Avoid vendor-specific IP. We want our designs to work on as many FPGAs as possible. See [FPGA Architecture](README.md#fpga-architecture) for examples of acceptable vendor-specific functionality.

## Development Language

Write your designs in SystemVerilog and follow the style of existing modules. Familiarise yourself with a few modules from the library before submitting a PR.

SystemVerilog has many valuable additions over older Verilog standards, but we restrict ourselves to simple, widely-supported SV features. See [SystemVerilog Features](README.md#systemverilog) for what's currently allowed.

## Additional Dev Boards

While we love to see Project F designs ported to new dev boards, we only accept new ports into the repo if we can test them. Otherwise, we won't be able to maintain your code after it's merged. If you want us to mention a fork, talk to us on the [Project F discussion forum](https://github.com/projf/projf-explore/discussions), and we'll consider linking to it from the Project F blog and docs.

## Linting

Designs must pass a Verilator lint with: `verilator --lint-only -Wall`

## Discuss Significant Changes

Use the [Project F discussion forum](https://github.com/projf/projf-explore/discussions) to discuss significant changes before submitting a PR.

## Small PRs

Please keep your PRs small. Submitting tens of new files or changes together makes testing and merging almost impossible.
