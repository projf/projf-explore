# Simulations for Racing the Beam

New demos for 2022.

_README will be completed later._

## Building

Build a specific simulation:

```shell
make rasterbars
```

Build all:

```shell
make all
```

You can run the simulation executables from `obj_dir`:

```shell
./obj_dir/square
```

If you want to manually build a simulation, try something like:

```shell
verilator -I../ -cc top_rasterbars.sv --exe main_rasterbars.cpp -o rasterbars \
    -CFLAGS "$(sdl2-config --cflags)" -LDFLAGS "$(sdl2-config --libs)"

make -C ./obj_dir -f Vtop_rasterbars.mk
```
