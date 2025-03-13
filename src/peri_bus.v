`default_nettype none

module peri_bus (
  input  wire        clk,
  input  wire        rst_n,
  input  wire [13:0] address,
  input  wire [31:0] write_data,
  output reg  [31:0] read_data,
  input  wire        we,
  input  wire        re,
  output wire [ 7:0] debug_out,
  output wire        uart_tx,
  input  wire        uart_rx,
  output wire        pwm_out
);

  localparam DEBUG_BASE  = 6'h01;
  localparam UART_BASE   = 6'h02;
  localparam TIME_BASE   = 6'h03;
  localparam PWM_BASE    = 6'h04;

  wire [7:0] func_addr;

  assign func_addr = address[7:0];

  // Debug
  wire [ 7:0] debug_data;
  
  wire debug_sel;
  wire debug_we;
  wire debug_re;

  assign debug_sel  = (address[12:8] == DEBUG_BASE);
  assign debug_we   = we & debug_sel;
  assign debug_re   = re & debug_sel;

  debug_module debug_inst (
    .clk        (clk),
    .rst_n      (rst_n),
    .address    (func_addr),
    .write_data (write_data),
    .read_data  (debug_data),
    .we         (debug_we),
    .re         (debug_re),
    .debug_out  (debug_out)
  );

  // UART
  wire [31:0] uart_data;

  wire uart_sel;
  wire uart_we;
  wire uart_re;

  assign uart_sel  = (address[12:8] == UART_BASE);
  assign uart_we   = we & uart_sel;
  assign uart_re   = re & uart_sel;

  uart #(
    .FIFO_TX_DEPTH(4),
    .FIFO_RX_DEPTH(4)
  ) uart_inst (
    .clk        (clk),
    .rst_n      (rst_n),
    .address    (func_addr),
    .write_data (write_data),
    .read_data  (uart_data),
    .we         (uart_we),
    .re         (uart_re),
    .uart_tx    (uart_tx),
    .uart_rx    (uart_rx)
  );

  // System Timer
  wire [31:0] time_data;

  wire time_sel;
  wire time_we;
  wire time_re;

  assign time_sel  = (address[12:8] == TIME_BASE);
  assign time_we   = we & time_sel;
  assign time_re   = re & time_sel;

  system_timer system_timer_inst (
    .clk        (clk),
    .rst_n      (rst_n),
    .address    (func_addr),
    .write_data (write_data),
    .read_data  (time_data),
    .we         (time_we),
    .re         (time_re)
  );

  // PWM Timer
  wire [31:0] pwm_data;

  wire pwm_sel;
  wire pwm_we;
  wire pwm_re;

  assign pwm_sel  = (address[12:8] == PWM_BASE);
  assign pwm_we   = we & pwm_sel;
  assign pwm_re   = re & pwm_sel;

  pwm_timer pwm_timer_inst (
    .clk        (clk),
    .rst_n      (rst_n),
    .address    (func_addr),
    .write_data (write_data),
    .read_data  (pwm_data),
    .we         (pwm_we),
    .re         (pwm_re),
    .pwm_out    (pwm_out)
  );

  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
      read_data <= 32'h0;
    else
    if (re)
    begin
      if (debug_sel)
        read_data <= debug_data;
      else if (uart_sel)
        read_data <= uart_data;
      else if (time_sel)
        read_data <= time_data;
      else if (pwm_sel)
        read_data <= pwm_data;
      else
        read_data <= 32'h0;
    end
  end

endmodule
