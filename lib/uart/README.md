# UART - Verilog Library

A UART was one of the first SystemVerilog designs I created. These designs are not polished, but I hope you find them useful.

You can freely build on these [MIT licensed](../../LICENSE) designs for commercial and non-commercial projects. See the [Library](../) for other helpful Verilog modules or discover the [background to the Library](https://projectf.io/posts/verilog-library-announcement/).

Learn more at [projectf.io](https://projectf.io/), follow [@WillFlux](https://twitter.com/WillFlux) for updates, and join the FPGA discussion on [1BitSquared Discord](https://1bitsquared.com/pages/chat).

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
