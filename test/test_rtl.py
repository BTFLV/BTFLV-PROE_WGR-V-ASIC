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

    dut._log.info("Showing first 128 debug outputs")
    debug_count = 0

    mem_write_val_last = 0;
    
    while debug_count < 128:
        req_ready = dut.user_project.system_memory.fram_inst.req_ready.value.integer

        ram_latched_addr = dut.user_project.system_memory.fram_inst.latched_addr.value.integer
        #ram_req_ready  = dut.user_project.system_memory.fram_inst.req_ready.value.integer

        #spi_state      = dut.user_project.system_memory.fram_inst.u_fram_spi.state.value.integer
        #spi_bit_count  = dut.user_project.system_memory.fram_inst.u_fram_spi.bit_count.value.integer
        #spi_spi_clk_en = dut.user_project.system_memory.fram_inst.u_fram_spi.spi_clk_en.value.integer
        #spi_shifting   = dut.user_project.system_memory.fram_inst.u_fram_spi.shifting.value.integer

        #state_val      = dut.user_project.rv32i_cpu.state.value.integer
        pc_val         = dut.user_project.rv32i_cpu.PC.value.integer
        #instr_val      = dut.user_project.rv32i_cpu.instruction.value.integer
        mem_addr_val   = dut.user_project.rv32i_cpu.address_reg.value.integer
        #mem_read_val   = dut.user_project.rv32i_cpu.mem_read.value.integer
        mem_write_val  = dut.user_project.rv32i_cpu.write_data.value.integer
        #mem_wdata_val  = dut.user_project.rv32i_cpu.mem_write_data.value.integer

        if (mem_write_val == 1) and (mem_write_val_last == 0):
            await ClockCycles(dut.clk, 1)
            debug_count += 1
            debug_reg      = dut.user_project.system_memory.peri_inst.debug_inst.debug_reg.value.integer
            dut._log.info(
                f"Debug: {debug_reg} ({debug_reg:08X}) PC: {pc_val:04X} latched_addr: 0x{ram_latched_addr:08X}"
            )
            if (debug_reg == 3735928559):
                dut._log.info("\n--- Simulation completed ---\n")
                return

        mem_write_val_last = mem_write_val;

        abort_count += 1
        if abort_count > 100:
            dut._log.info("Aborting test due to timeout")
            break
        
        await ClockCycles(dut.clk, 1)
