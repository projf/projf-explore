## Project F Library - mul Test Bench (cocotb)
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

async def test_dut_multiply(dut, a, b, log=True):
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

    # model product
    model_c = fp_family(float(fp_family(a)) * float(fp_family(b)))

    # divide dut result by scaling factor
    val = fp_family(dut.val.value.signed_integer/2**FBITS)

    # log numberical signals
    if (log):
        dut._log.info('dut a:     ' + dut.a.value.binstr)
        dut._log.info('dut b:     ' + dut.b.value.binstr)
        dut._log.info('dut val:   ' + dut.val.value.binstr)
        dut._log.info('           ' + val.toDecimalString(precision=fp_family.fraction_bits))
        dut._log.info('model val: ' + model_c.toBinaryString())
        dut._log.info('           ' + model_c.toDecimalString(precision=fp_family.fraction_bits))

    # check output signals on 'done'
    assert dut.busy.value == 0, "busy is not 0!"
    assert dut.done.value == 1, "done is not 1!"
    assert dut.valid.value == 1, "valid is not 1!"
    assert dut.ovf.value == 0, "ovf is not 0!"
    assert val == model_c, "dut val doesn't match model val"

    # check 'done' is high for one tick
    await RisingEdge(dut.clk)
    assert dut.done.value == 0, "done is not 0!"


# simple tests
@cocotb.test()
async def simple_1(dut):
    """Test 1*1"""
    await test_dut_multiply(dut=dut, a=1, b=1)

@cocotb.test()
async def simple_2(dut):
    """Test -1*1"""
    await test_dut_multiply(dut=dut, a=-1, b=1)

@cocotb.test()
async def simple_3(dut):
    """Test 3*2"""
    await test_dut_multiply(dut=dut, a=3, b=2)

@cocotb.test()
async def simple_4(dut):
    """Test 1.5*2"""
    await test_dut_multiply(dut=dut, a=1.5, b=2)

@cocotb.test()
async def simple_5(dut):
    """Test 1*0.0625"""
    await test_dut_multiply(dut=dut, a=1, b=0.0625)

@cocotb.test()
async def simple_6(dut):
    """Test 3*0"""
    await test_dut_multiply(dut=dut, a=3, b=0)


# wider values
@cocotb.test()
async def wide_1(dut):
    """Test 3.4375*4.5"""
    await test_dut_multiply(dut=dut, a=3.4375, b=4.5)

@cocotb.test()
async def wide_2(dut):
    """Test -3.4375*4.5"""
    await test_dut_multiply(dut=dut, a=-3.4375, b=4.5)

@cocotb.test()
async def wide_3(dut):
    """Test -3.4375*-4.5"""
    await test_dut_multiply(dut=dut, a=-3.4375, b=-4.5)


# rounding: 2.5, 3.5, 4.5, 5.5
@cocotb.test()
async def round_1(dut):
    """Test 2.5*2.0625"""
    await test_dut_multiply(dut=dut, a=2.5, b=2.0625)

@cocotb.test()
async def round_2(dut):
    """Test 3.5*2.0625"""
    await test_dut_multiply(dut=dut, a=3.5, b=2.0625)

@cocotb.test()
async def round_3(dut):
    """Test 4.5*2.0625"""
    await test_dut_multiply(dut=dut, a=4.5, b=2.0625)

@cocotb.test()
async def round_4(dut):
    """Test 5.5*2.0625"""
    await test_dut_multiply(dut=dut, a=5.5, b=2.0625)

# rounding: either side of 3.5
@cocotb.test()
async def round_5(dut):
    """Test 3.4375*2.0625"""
    await test_dut_multiply(dut=dut, a=3.4375, b=2.0625)

@cocotb.test()
async def round_6(dut):
    """Test 3.5625*2.0625"""
    await test_dut_multiply(dut=dut, a=3.5625, b=2.0625)

# rounding: -2.5, -3.5, -4.5, -5.5
@cocotb.test()
async def round_neg_1(dut):
    """Test -2.5*2.0625"""
    await test_dut_multiply(dut=dut, a=-2.5, b=2.0625)

@cocotb.test()
async def round_neg_2(dut):
    """Test -3.5*2.0625"""
    await test_dut_multiply(dut=dut, a=-3.5, b=2.0625)

@cocotb.test()
async def round_neg_3(dut):
    """Test -4.5*2.0625"""
    await test_dut_multiply(dut=dut, a=-4.5, b=2.0625)

@cocotb.test()
async def round_neg_4(dut):
    """Test -5.5*2.0625"""
    await test_dut_multiply(dut=dut, a=-5.5, b=2.0625)

# rounding: either side of -3.5
@cocotb.test()
async def round_neg_5(dut):
    """Test -3.4375*2.0625"""
    await test_dut_multiply(dut=dut, a=-3.4375, b=2.0625)

@cocotb.test()
async def round_neg_6(dut):
    """Test -3.5625*2.0625"""
    await test_dut_multiply(dut=dut, a=-3.5625, b=2.0625)


# test non-binary values (can't be precisely represented in binary)
@cocotb.test()
async def nonbin_1(dut):
    """Test 1*0.2"""
    await test_dut_multiply(dut=dut, a=1, b=0.2)

@cocotb.test()
async def nonbin_2(dut):
    """Test 1.9*0.2"""
    await test_dut_multiply(dut=dut, a=1.9, b=0.2)

@cocotb.test()
async def nonbin_3(dut):
    """Test 0.4/0.2"""
    await test_dut_multiply(dut=dut, a=0.4, b=0.2)

# test fails - model and DUT choose different sides of true value
@cocotb.test(expect_fail=True)
async def nonbin_4(dut):
    """Test 3.6*0.6"""
    await test_dut_multiply(dut=dut, a=3.6, b=0.6)

# test fails - model and DUT choose different sides of true value
@cocotb.test(expect_fail=True)
async def nonbin_5(dut):
    """Test 0.4*0.1"""
    await test_dut_multiply(dut=dut, a=0.4, b=0.1)


# overflow tests
@cocotb.test()
async def ovf_1(dut):
    """Test 8*8 [overflow]"""
    cocotb.start_soon(Clock(dut.clk, 1, units="ns").start())
    await reset_dut(dut)

    await RisingEdge(dut.clk)
    a = 8
    b = 8
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
    assert dut.ovf.value == 1, "ovf is not 1!"

    # check 'done' is high for one tick
    await RisingEdge(dut.clk)
    assert dut.done.value == 0, "done is not 0!"

@cocotb.test()
async def ovf_2(dut):
    """Test 5*4 [overflow]"""
    cocotb.start_soon(Clock(dut.clk, 1, units="ns").start())
    await reset_dut(dut)

    await RisingEdge(dut.clk)
    a = 5
    b = 4
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
    assert dut.ovf.value == 1, "ovf is not 1!"

    # check 'done' is high for one tick
    await RisingEdge(dut.clk)
    assert dut.done.value == 0, "done is not 0!"

@cocotb.test()
async def ovf_3(dut):
    """Test -7*3 [overflow]"""
    cocotb.start_soon(Clock(dut.clk, 1, units="ns").start())
    await reset_dut(dut)

    await RisingEdge(dut.clk)
    a = -7
    b = 3
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
    assert dut.ovf.value == 1, "ovf is not 1!"

    # check 'done' is high for one tick
    await RisingEdge(dut.clk)
    assert dut.done.value == 0, "done is not 0!"
