## Project F Library - div Test Bench (cocotb)
## (C)2023 Will Green, open source software released under the MIT License
## Learn more at https://projectf.io/verilog-lib/

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

from FixedPoint import FXfamily, FXnum

WIDTH=9  # must match Makefile
FBITS=4  # must match Makefile
fp_family = FXfamily(n_bits=FBITS, n_intbits=WIDTH-FBITS+1)  # need +1 because n_intbits includes sign

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
    dut.a.value = int(a * 2**FBITS)
    dut.b.value = int(b * 2**FBITS)
    dut.start.value = 1

    await RisingEdge(dut.clk)
    dut.start.value = 0

    # wait for calculation to complete
    while not dut.done.value:
        await RisingEdge(dut.clk)

    # model quotient
    model_val = fp_family(a / b)

    # divide dut result by scaling factor
    val = fp_family(dut.val.value.signed_integer/2**FBITS)

    # log numberical signals
    if (log):
        dut._log.info('dut a:     ' + dut.a.value.binstr)
        dut._log.info('dut b:     ' + dut.b.value.binstr)
        dut._log.info('dut val:   ' + dut.val.value.binstr)
        dut._log.info('           ' + val.toDecimalString(precision=fp_family.fraction_bits))
        dut._log.info('model val: ' + model_val.toBinaryString())
        dut._log.info('           ' + model_val.toDecimalString(precision=fp_family.fraction_bits))

    # check output signals on 'done'
    assert dut.busy.value == 0, "busy is not 0!"
    assert dut.done.value == 1, "done is not 1!"
    assert dut.valid.value == 1, "valid is not 1!"
    assert dut.dbz.value == 0, "dbz is not 0!"
    assert dut.ovf.value == 0, "ovf is not 0!"
    assert val == model_val, "dut val doesn't match model val"

    # check 'done' is high for one tick
    await RisingEdge(dut.clk)
    assert dut.done.value == 0, "done is not 0!"


# simple division tests (no rounding required)
@cocotb.test()
async def simple_1(dut):
    """Test 6/2"""
    await test_dut_divide(dut=dut, a=6, b=2)

@cocotb.test()
async def simple_2(dut):
    """Test 15/3"""
    await test_dut_divide(dut=dut, a=15, b=3)

@cocotb.test()
async def simple_3(dut):
    """Test 13/4"""
    await test_dut_divide(dut=dut, a=13, b=4)

@cocotb.test()
async def simple_4(dut):
    """Test 3/12"""
    await test_dut_divide(dut=dut, a=3, b=12)

@cocotb.test()
async def simple_5(dut):
    """Test 7.5/2"""
    await test_dut_divide(dut=dut, a=7.5, b=2)


# sign tests
@cocotb.test()
async def sign_1(dut):
    """Test 3/2"""
    await test_dut_divide(dut=dut, a=3, b=2)

@cocotb.test()
async def sign_2(dut):
    """Test -3/2"""
    await test_dut_divide(dut=dut, a=-3, b=2)

@cocotb.test()
async def sign_3(dut):
    """Test 3/-2"""
    await test_dut_divide(dut=dut, a=3, b=-2)

@cocotb.test()
async def sign_4(dut):
    """Test -3/-2"""
    await test_dut_divide(dut=dut, a=-3, b=-2)


# rounding tests
@cocotb.test()
async def round_1(dut):
    """Test 5.0625/2"""
    await test_dut_divide(dut=dut, a=5.0625, b=2)

@cocotb.test()
async def round_2(dut):
    """Test 7.0625/2"""
    await test_dut_divide(dut=dut, a=7.0625, b=2)

@cocotb.test()
async def round_3(dut):
    """Test 15.9375/2"""
    await test_dut_divide(dut=dut, a=15.9375, b=2)

@cocotb.test()
async def round_4(dut):
    """Test 14.9375/2"""
    await test_dut_divide(dut=dut, a=14.9375, b=2)

@cocotb.test()
async def round_5(dut):
    """Test 13/7"""
    await test_dut_divide(dut=dut, a=13, b=7)

@cocotb.test()
async def round_6(dut):
    """Test 8.1875/4"""
    await test_dut_divide(dut=dut, a=8.1875, b=4)

@cocotb.test()
async def round_7(dut):
    """Test 12.3125/8"""
    await test_dut_divide(dut=dut, a=12.3125, b=8)

@cocotb.test()
async def round_8(dut):  # negative
    """Test -7.0625/2"""
    await test_dut_divide(dut=dut, a=-7.0625, b=2)

@cocotb.test()
async def round_9(dut):  # negative
    """Test -5.0625/2"""
    await test_dut_divide(dut=dut, a=-5.0625, b=2)


# min edge tests
@cocotb.test()
async def min_1(dut):
    """Test 0.125/2"""
    await test_dut_divide(dut=dut, a=0.125, b=2)

@cocotb.test()
async def min_2(dut):
    """Test 0.0625/2"""
    await test_dut_divide(dut=dut, a=0.0625, b=2)

@cocotb.test()
async def min_3(dut):
    """Test 0/2"""
    await test_dut_divide(dut=dut, a=0, b=2)

@cocotb.test()
async def min_4(dut):  # negative
    """Test -0.0625/2"""
    await test_dut_divide(dut=dut, a=-0.0625, b=2)

@cocotb.test()
async def min_5(dut):
    """Test 1/0.2"""
    await test_dut_divide(dut=dut, a=1, b=0.2)

# max edge tests
@cocotb.test()
async def max_1(dut):
    """Test 15.9375/1"""
    await test_dut_divide(dut=dut, a=15.9375, b=1)

@cocotb.test()
async def max_2(dut):
    """Test 7.9375/0.5"""
    await test_dut_divide(dut=dut, a=7.9375, b=0.5)

@cocotb.test()
async def max_3(dut):  # negative
    """Test -15.9375/1"""
    await test_dut_divide(dut=dut, a=-15.9375, b=1)

@cocotb.test()
async def max_4(dut):  # negative
    """Test -7.9375/0.5"""
    await test_dut_divide(dut=dut, a=-7.9375, b=0.5)


# divide by zero and overflow tests
@cocotb.test()
async def dbz_1(dut):
    """Test 2/0 [div by zero]"""
    cocotb.start_soon(Clock(dut.clk, 1, units="ns").start())
    await reset_dut(dut)

    await RisingEdge(dut.clk)
    a = 2
    b = 0
    dut.a.value = int(a * 2**FBITS)
    dut.b.value = int(b * 2**FBITS)
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
    assert dut.ovf.value == 0, "ovf is not 0!"

    # check 'done' is high for one tick
    await RisingEdge(dut.clk)
    assert dut.done.value == 0, "done is not 0!"

@cocotb.test()
async def dbz_2(dut):
    """Test 13/4 [after dbz]"""
    await test_dut_divide(dut=dut, a=13, b=4)

@cocotb.test()
async def ovf_1(dut):
    """Test 8/0.25 [overflow]"""
    cocotb.start_soon(Clock(dut.clk, 1, units="ns").start())
    await reset_dut(dut)

    await RisingEdge(dut.clk)
    a = 8
    b = 0.25
    dut.a.value = int(a * 2**FBITS)
    dut.b.value = int(b * 2**FBITS)
    dut.start.value = 1

    await RisingEdge(dut.clk)
    dut.start.value = 0

    # wait for calculation to complete
    while not dut.done.value:
        await RisingEdge(dut.clk)

    # check output signals on 'done'
    assert dut.busy.value == 0, "busy is not 0!"
    assert dut.done.value == 1, "done is not 1!"
    assert dut.valid.value == 0, "valid is not 0"
    assert dut.dbz.value == 0, "dbz is not 0!"
    assert dut.ovf.value == 1, "ovf is not 1!"

    # check 'done' is high for one tick
    await RisingEdge(dut.clk)
    assert dut.done.value == 0, "done is not 0!"

@cocotb.test()
async def ovf_2(dut):
    """Test 11/7 [after ovf]"""
    await test_dut_divide(dut=dut, a=11, b=7)

@cocotb.test()
async def ovf_3(dut):
    """Test -16/1 [overflow]"""
    cocotb.start_soon(Clock(dut.clk, 1, units="ns").start())
    await reset_dut(dut)

    await RisingEdge(dut.clk)
    a = -16
    b = 1
    dut.a.value = int(a * 2**FBITS)
    dut.b.value = int(b * 2**FBITS)
    dut.start.value = 1

    await RisingEdge(dut.clk)
    dut.start.value = 0

    # wait for calculation to complete
    while not dut.done.value:
        await RisingEdge(dut.clk)

    # check output signals on 'done'
    assert dut.busy.value == 0, "busy is not 0!"
    assert dut.done.value == 1, "done is not 1!"
    assert dut.valid.value == 0, "valid is not 0"
    assert dut.dbz.value == 0, "dbz is not 0!"
    assert dut.ovf.value == 1, "ovf is not 1!"

    # check 'done' is high for one tick
    await RisingEdge(dut.clk)
    assert dut.done.value == 0, "done is not 0!"

@cocotb.test()
async def ovf_4(dut):
    """Test 1/-16 [overflow]"""
    cocotb.start_soon(Clock(dut.clk, 1, units="ns").start())
    await reset_dut(dut)

    await RisingEdge(dut.clk)
    a = 1
    b = -16
    dut.a.value = int(a * 2**FBITS)
    dut.b.value = int(b * 2**FBITS)
    dut.start.value = 1

    await RisingEdge(dut.clk)
    dut.start.value = 0

    # wait for calculation to complete
    while not dut.done.value:
        await RisingEdge(dut.clk)

    # check output signals on 'done'
    assert dut.busy.value == 0, "busy is not 0!"
    assert dut.done.value == 1, "done is not 1!"
    assert dut.valid.value == 0, "valid is not 0"
    assert dut.dbz.value == 0, "dbz is not 0!"
    assert dut.ovf.value == 1, "ovf is not 1!"

    # check 'done' is high for one tick
    await RisingEdge(dut.clk)
    assert dut.done.value == 0, "done is not 0!"
