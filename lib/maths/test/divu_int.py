## Project F Library - divu_int Test Bench (cocotb)
## (C)2023 Will Green, open source software released under the MIT License
## Learn more at https://projectf.io/verilog-lib/

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

async def reset_dut(dut):
    await RisingEdge(dut.clk)
    dut.rst.value = 0
    await RisingEdge(dut.clk)
    dut.rst.value = 1
    await RisingEdge(dut.clk)
    dut.rst.value = 0
    await RisingEdge(dut.clk)

async def test_dut_divide(dut, a, b, log=True):
    cocotb.start_soon(Clock(dut.clk, 1, units="ns").start())
    await reset_dut(dut)

    await RisingEdge(dut.clk)
    dut.a.value = a
    dut.b.value = b
    dut.start.value = 1

    await RisingEdge(dut.clk)
    dut.start.value = 0

    # wait for calculation to complete
    while not dut.done.value:
        await RisingEdge(dut.clk)

    # model division
    model_c = a // b
    model_r = a % b

    # log numberical signals (note width formatting of model answers)
    if (log):
        dut._log.info('dut a:     ' + dut.a.value.binstr)
        dut._log.info('dut b:     ' + dut.b.value.binstr)
        dut._log.info('dut val:   ' + dut.val.value.binstr)
        dut._log.info('dut rem:   ' + dut.rem.value.binstr)
        dut._log.info('model val: ' + '{0:08b}'.format(model_c))
        dut._log.info('model rem: ' + '{0:08b}'.format(model_r))

    # check output signals on 'done'
    assert dut.busy.value == 0, "busy is not 0!"
    assert dut.done.value == 1, "done is not 1!"
    assert dut.valid.value == 1, "valid is not 1!"
    assert dut.dbz.value == 0, "dbz is not 0!"
    assert dut.val.value == model_c, "dut val doesn't match model val"
    assert dut.rem.value == model_r, "dut rem doesn't match model rem"

    # check 'done' is high for one tick
    await RisingEdge(dut.clk)
    assert dut.done.value == 0, "done is not 0!"


# simple division tests (no remainder)
@cocotb.test()
async def simple_1(dut):
    """Test 1/1"""
    await test_dut_divide(dut=dut, a=1, b=1)

@cocotb.test()
async def simple_2(dut):
    """Test 0/2"""
    await test_dut_divide(dut=dut, a=0, b=2)

@cocotb.test()
async def simple_3(dut):
    """Test 6/2"""
    await test_dut_divide(dut=dut, a=6, b=2)

@cocotb.test()
async def simple_4(dut):
    """Test 15/3"""
    await test_dut_divide(dut=dut, a=15, b=3)

@cocotb.test()
async def simple_5(dut):
    """Test 15/5"""
    await test_dut_divide(dut=dut, a=15, b=5)


# remainder tests
@cocotb.test()
async def rem_1(dut):
    """Test 7/2"""
    await test_dut_divide(dut=dut, a=7, b=2)

@cocotb.test()
async def rem_2(dut):
    """Test 2/7"""
    await test_dut_divide(dut=dut, a=2, b=7)

@cocotb.test()
async def rem_3(dut):
    """Test 97/13"""
    await test_dut_divide(dut=dut, a=97, b=13)


# edge tests
@cocotb.test()
async def edge_1(dut):
    """Test 255/16"""
    await test_dut_divide(dut=dut, a=255, b=16)

@cocotb.test()
async def edge_2(dut):
    """Test 255/255"""
    await test_dut_divide(dut=dut, a=255, b=255)

@cocotb.test()
async def edge_3(dut):
    """Test 255/254"""
    await test_dut_divide(dut=dut, a=255, b=254)

@cocotb.test()
async def edge_4(dut):
    """Test 254/255"""
    await test_dut_divide(dut=dut, a=254, b=255)


# divide by zero tests
@cocotb.test()
async def dbz_1(dut):
    """Test 2/0 [div by zero]"""
    cocotb.start_soon(Clock(dut.clk, 1, units="ns").start())
    await reset_dut(dut)

    await RisingEdge(dut.clk)
    a = 2
    b = 0
    dut.a.value = a
    dut.b.value = b
    dut.start.value = 1

    await RisingEdge(dut.clk)
    dut.start.value = 0
    # wait for calculation to complete
    while not dut.done.value:
        await RisingEdge(dut.clk)

    # check output signals on 'done'
    assert dut.busy.value == 0, "busy is not 0!"
    assert dut.done.value == 1, "done is not 1!"
    assert dut.valid.value == 0, "valid is not 0!"
    assert dut.dbz.value == 1, "dbz is not 1!"

    # check 'done' is high for one tick
    await RisingEdge(dut.clk)
    assert dut.done.value == 0, "done is not 0!"

@cocotb.test()
async def dbz_2(dut):
    """Test 251/13 [after dbz]"""
    await test_dut_divide(dut=dut, a=251, b=13)
