# Contributing to Project F

Project F welcomes contributions from beginners and experts alike. We have a few simple policies to ensure new designs are compatible with the project goals. This document is a new draft for autumn 2021; expect additional guidelines over the coming months.

## Philosophy 

### Simple

Our designs are self-contained and simple to understand. Overly clever or complex designs are unlikely to be accepted.

### Universal

Avoid vendor-specific IP. We want our designs to work on as many FPGAs as possible. See [FPGA Architecture](README.md#fpga-architecture) for examples of acceptable vendor-specific functionality. 

## Coding Standards

### Development Language

Designs must be written in SystemVerilog and follow the style of existing modules. Familiarise yourself with a few modules from the library before submitting changes.

We write designs in SystemVerilog, but using only a few beneficial SV features for simplicity and compatibility. See [SystemVerilog Features](README.md#systemverilog) for what's allowed.

### Linting

Designs must pass a Verilator lint with: `verilator --lint-only -Wall`
