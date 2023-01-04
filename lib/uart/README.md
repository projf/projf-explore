# UART - Verilog Library

A UART was one of the first SystemVerilog designs I created. These designs are not polished, but I hope you find them useful. You can freely build on these [MIT licensed](../../LICENSE) designs. Get an overview of the whole lib from the [Verilog Library blog](https://projectf.io/verilog-lib/).

## Verilog Modules

* [uart_baud.sv](uart_baud.sv) - UART baud rate generator
* [uart_rx.sv](uart_rx.sv) - UART receiver (to FPGA)
* [uart_tx.sv](uart_tx.sv) - UART transmitter (from FPGA)

### Test Benches

_Test benches still need to be added for UART._

### Examples

* [top_uart.sv](examples/top_uart.sv) - echo example at 9600 baud (8N1)

_NB. Transmit and receive are from the point of view of the FPGA._

## Blog Posts

No Project F blog posts reference these modules as yet.

## SystemVerilog?

These modules use a little SystemVerilog to make Verilog more pleasant, see the main [Library README](../README.md#systemverilog) for details.
