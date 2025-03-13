`default_nettype none
`timescale 1ns / 1ps

module tb ();

  initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, tb);
    #1;
  end

  reg        clk;
  reg        rst_n;
  reg        ena;
  wire       spi_miso;
  reg  [7:0] uio_in;
  reg  [7:0] ui_in;
  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;
  wire       spi_mosi = uo_out[0];
  wire       spi_sck = uo_out[1];
  wire       spi_cs = uo_out[2];
  assign ui_in[0] = spi_miso;

`ifdef GL_TEST
  wire VPWR = 1'b1;
  wire VGND = 1'b0;
`endif

  assign ui_in[7:1] = {6'b0, 1'b1};

  // ui_in[0] : spi_miso
  // ui_in[1] : uart_rx
  // uo_out[0]: spi_mosi
  // uo_out[1]: spi_sck
  // uo_out[2]: spi_cs
  // uo_out[3]: pwm_out
  // uo_out[4]: uart_tx
  // uo_out[5]: mem_read
  // uo_out[6]: mem_write
  // uo_out[7]: mem_busy

  tt_um_wgr_v user_project (
`ifdef GL_TEST
      .VPWR   (VPWR),
      .VGND   (VGND),
`endif
      .ui_in  (ui_in),
      .uo_out (uo_out),
      .uio_in (uio_in),
      .uio_out(uio_out),
      .uio_oe (uio_oe),
      .ena    (ena),
      .clk    (clk),
      .rst_n  (rst_n)
  );

  mb85rs64v mb85rs64v_inst (
      .clk    (clk),
      .rst_n  (rst_n),
      .cs     (spi_cs),
      .spi_sck(spi_sck),
      .mosi   (spi_mosi),
      .miso   (spi_miso)
  );

  initial begin
    $readmemh("wgr_fram.hex", mb85rs64v_inst.memory);
  end

  initial begin
    clk = 0;
    forever #50 clk = ~clk;
  end

  initial begin
    rst_n = 0;
    ena   = 0;
    #200;
    rst_n = 1;
    ena   = 1;
  end

  initial begin
    uio_in = 8'h00;
  end

  initial begin
    uio_in = 8'h00;
  end

endmodule
