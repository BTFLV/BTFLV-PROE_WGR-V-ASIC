`default_nettype none

module tt_um_wgr_v (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);
  // ui_in[0] : spi_miso
  // ui_in[1] : uart_rx
  // uo_out[0]: spi_mosi
  // uo_out[1]: spi_clk
  // uo_out[2]: spi_cs
  // uo_out[3]: pwm_out
  // uo_out[4]: uart_tx
  // uo_out[5]: mem_read
  // uo_out[6]: mem_write
  // uo_out[7]: mem_busy

  wire [31:0] mem_addr;
  wire [31:0] mem_write_data;
  wire [31:0] mem_read_data;
  wire [ 7:0] debug_out;
  wire        mem_read;
  wire        mem_write;
  wire        mem_busy;
  wire        spi_miso;
  wire        spi_mosi;
  wire        spi_clk;
  wire        spi_cs;
  wire        pwm_out;
  wire        uart_tx;
  wire        uart_rx;

  cpu rv32i_cpu (
    .clk        (clk),
    .rst_n      (rst_n),
    .address    (mem_addr),
    .write_data (mem_write_data),
    .read_data  (mem_read_data),
    .we         (mem_write),
    .re         (mem_read),
    .mem_busy   (mem_busy)
  );

  memory system_memory (
      .clk       (clk),
      .rst_n     (rst_n),
      .address   (mem_addr),
      .write_data(mem_write_data),
      .read_data (mem_read_data),
      .we        (mem_write),
      .re        (mem_read),
      .debug_out (debug_out),
      .pwm_out   (pwm_out),
      .spi_mosi  (spi_mosi),
      .spi_miso  (spi_miso),
      .spi_clk   (spi_clk),
      .spi_cs    (spi_cs),
      .mem_busy  (mem_busy),
      .uart_tx   (uart_tx),
      .uart_rx   (uart_rx)
  );

  assign spi_miso     = ui_in[0];
  assign uart_rx      = ui_in[1];
  assign uo_out[0]    = spi_mosi;
  assign uo_out[1]    = spi_clk;
  assign uo_out[2]    = spi_cs;
  assign uo_out[3]    = pwm_out;
  assign uo_out[4]    = uart_tx;
  assign uo_out[5]    = mem_read;
  assign uo_out[6]    = mem_write;
  assign uo_out[7]    = mem_busy;

  assign uio_out[7:0] = debug_out[7:0];
  assign uio_oe       = 8'hFF;

  wire _unused = &{ui_in[7:2], uio_in, ena};

endmodule
