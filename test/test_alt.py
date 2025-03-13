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

    #
    # 1) FIRST DEBUG LOOP: Up to 128 non-stall cycles
    #
    dut._log.info("Starting debug for first 128 non-stall cycles")
    nonstall_count = 0
    while nonstall_count < 128:
        # mem_busy is bit 7 of uo_out (as per your top-level mapping)
        req_ready = dut.user_project.system_memory.fram_inst.req_ready.value.integer

        if req_ready == 1:
            nonstall_count += 1

        

        # Extracting values for RAM and SPI states
        ram_state      = dut.user_project.system_memory.fram_inst.state.value.integer
        ram_byte_idx   = dut.user_project.system_memory.fram_inst.byte_idx.value.integer
        ram_latched_addr = dut.user_project.system_memory.fram_inst.latched_addr.value.integer
        ram_req_ready  = dut.user_project.system_memory.fram_inst.req_ready.value.integer

        spi_state      = dut.user_project.system_memory.fram_inst.u_fram_spi.state.value.integer
        spi_bit_count  = dut.user_project.system_memory.fram_inst.u_fram_spi.bit_count.value.integer
        spi_spi_clk_en = dut.user_project.system_memory.fram_inst.u_fram_spi.spi_clk_en.value.integer
        spi_shifting   = dut.user_project.system_memory.fram_inst.u_fram_spi.shifting.value.integer

        # Extracting existing CPU signals
        state_val      = dut.user_project.rv32i_cpu.state.value.integer
        pc_val         = dut.user_project.rv32i_cpu.PC.value.integer
        instr_val      = dut.user_project.rv32i_cpu.instruction.value.integer
        mem_addr_val   = dut.user_project.rv32i_cpu.mem_addr_reg.value.integer
        mem_read_val   = dut.user_project.rv32i_cpu.mem_read.value.integer
        mem_write_val  = dut.user_project.rv32i_cpu.mem_write.value.integer
        mem_wdata_val  = dut.user_project.rv32i_cpu.mem_write_data.value.integer

        debug_reg = dut.user_project.system_memory.peri_inst.debug_inst.debug.value.integer

        if ram_state != 0:
            dut._log.info(
                f"RAM state={ram_state} byte_idx={ram_byte_idx} latched_addr=0x{ram_latched_addr:08X} "
                f"req_ready={ram_req_ready} | "
                f"SPI state={spi_state} bit_count={spi_bit_count} spi_clk_en={spi_spi_clk_en} "
                f"shifting={spi_shifting}"
            )
        else:
            dut._log.info(
                f"Nonstall cycle {nonstall_count:03d} | "
                f"state={state_val} PC=0x{pc_val:08X} instr=0x{instr_val:08X} "
                f"mem_addr=0x{mem_addr_val:08X} re={mem_read_val} we={mem_write_val} "
                f"wdata=0x{mem_wdata_val:08X}"
            )

        await ClockCycles(dut.clk, 1)

    #
    # 2) MAIN LOOP: 16k cycles with your existing read/write edge logging
    #
    dut._log.info("Starting main test loop for 16384 clock cycles")
    previous_read  = 0
    previous_write = 0
    previous_state = 0

    for _ in range(16384):
        await RisingEdge(dut.clk)

        mem_read  = dut.user_project.rv32i_cpu.mem_read.value.integer
        mem_write = dut.user_project.rv32i_cpu.mem_write.value.integer
        mem_addr = dut.user_project.rv32i_cpu.mem_addr_reg.value.integer
        state     = dut.user_project.rv32i_cpu.state.value.integer

        read_rise_edge  = (previous_read  == 0 and mem_read  == 1)
        write_rise_edge = (previous_write == 0 and mem_write == 1)
        state_change    = (previous_state != state)

        if state_change:
            dut._log.info(f"CPU state: {state}")

        if read_rise_edge:
            pc_val = dut.user_project.rv32i_cpu.PC.value.integer
            instr_val = dut.user_project.rv32i_cpu.instruction.value.integer
            dut._log.info(
                f"MEM READ at address {mem_addr}, "
                f"Instruction: 0x{instr_val:08X}, PC: {pc_val}"
            )

        if write_rise_edge:
            pc_val = dut.user_project.rv32i_cpu.PC.value.integer
            instr_val = dut.user_project.rv32i_cpu.instruction.value.integer
            dut._log.info(
                f"MEM WRITE at address {mem_addr}, "
                f"Instruction: 0x{instr_val:08X}, PC: {pc_val}"
            )

        previous_read  = mem_read
        previous_write = mem_write
        previous_state = state

    dut._log.info("Simulation complete after 16384 clock cycles")
