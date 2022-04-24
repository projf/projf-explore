# Simulations for Ad Astra

New demos for 2022.

_README will be completed later._

**Update with new Makefiles from Racing the Beam**

## FPGA Ad Astra

### LFSR

```shell
export PROJF_LIB="../../../lib" 
verilator -I../ -I${PROJF_LIB}/display -I${PROJF_LIB}/maths \
    -cc top_lfsr.sv --exe main_lfsr.cpp -o lfsr \
    -CFLAGS "$(sdl2-config --cflags)" -LDFLAGS "$(sdl2-config --libs)" \
&& make -C ./obj_dir -f Vtop_lfsr.mk
```
