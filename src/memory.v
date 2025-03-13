`default_nettype none

module memory (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] address,
    input  wire [31:0] write_data,
    output wire [31:0] read_data,
    input  wire        we,
    input  wire        re,
    output wire [ 7:0] debug_out,
    output wire        pwm_out,
    output wire        mem_busy,
    output wire        spi_mosi,
    input  wire        spi_miso,
    output wire        spi_clk,
    output wire        spi_cs,
    output wire        uart_tx,
    input  wire        uart_rx
);

  wire        is_ram = (address >= 32'h00004000);
  wire [31:0] ram_addr = address - 32'h00004000;

  wire [31:0] fram_rdata;
  wire        req_ready;

  wire        ram_re = re && is_ram;
  wire        ram_we = we && is_ram;
  wire        peri_re = re && ~is_ram;
  wire        peri_we = we && ~is_ram;

  assign read_data = is_ram ? fram_rdata : peri_rdata;
  assign mem_busy  = !req_ready;

  fram_ram fram_inst (
      .clk       (clk),
      .rst_n     (rst_n),
      .read_en   (ram_re),
      .write_en  (ram_we),
      .req_ready (req_ready),
      .addr      (ram_addr[15:0]),
      .wdata     (write_data),
      .rdata     (fram_rdata),
      .spi_clk   (spi_clk),
      .spi_cs_n  (spi_cs),
      .spi_mosi  (spi_mosi),
      .spi_miso  (spi_miso)
  );

  wire [31:0] peri_rdata;
  peri_bus peri_inst (
      .clk       (clk),
      .rst_n     (rst_n),
      .address   (address[13:0]),
      .write_data(write_data),
      .we        (peri_we),
      .re        (peri_re),
      .read_data (peri_rdata),
      .debug_out (debug_out),
      .pwm_out   (pwm_out),
      .uart_tx   (uart_tx),
      .uart_rx   (uart_rx)
  );

endmodule
