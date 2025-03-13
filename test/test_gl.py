import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, FallingEdge

@cocotb.test()
async def test_project(dut):
    dut._log.info("Start Simulation")

    # Set the clock period to 10 MHz (100 ns per cycle)
    clock = Clock(dut.clk, 100, units="ns")
    cocotb.start_soon(clock.start())

    # Reset sequence
    dut._log.info("Resetting DUT")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    dut._log.info("Reset complete")

    for i in range(8):
        byte_val = dut.mb85rs64v_inst.memory[i].value.integer
        dut._log.info(f"Memory[{i:02d}] = 0x{byte_val:02X}")

    abort_count = 0

    dut._log.info("Showing first 512 debug outputs")
    debug_count = 0

    while debug_count < 512:
        mem_write_val  = (dut.uo_out.value.integer >> 6) & 1

        if (mem_write_val == 1):
            await ClockCycles(dut.clk, 2)
            mem_busy  = (dut.uo_out.value.integer >> 7) & 1
            if(mem_busy == 0):
                debug_count += 1
                debug_reg = dut.uio_out.value.integer
                dut._log.info(
                    f"Debug: {debug_reg} ({debug_reg:02X})"
                )

        abort_count += 1
        if abort_count > 1000000:
            dut._log.error("Aborting test due to timeout")
            break
        
        await ClockCycles(dut.clk, 1)

    dut._log.info("Simulation completed")