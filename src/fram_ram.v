`default_nettype none

module fram_ram (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        read_en,
    input  wire        write_en,
    output reg         req_ready,
    input  wire [15:0] addr,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata,
    output wire        spi_clk,
    output wire        spi_cs_n,
    output wire        spi_mosi,
    input  wire        spi_miso
);

  localparam [2:0] ST_IDLE = 3'd0, ST_START = 3'd1, ST_WAIT = 3'd2, ST_DONE = 3'd3;

  reg  [ 2:0] state;

  reg         latched_write;
  reg  [15:0] latched_addr;
  reg  [31:0] latched_wdata;

  reg         spi_read_en;
  reg         spi_write_en;
  reg  [15:0] spi_addr;
  reg  [31:0] spi_wdata;

  wire [31:0] spi_rdata;
  wire        spi_done;

  fram_spi u_fram_spi (
      .clk          (clk),
      .rst_n        (rst_n),
      .addr         (spi_addr),
      .write_data   (spi_wdata),
      .read_enable  (spi_read_en),
      .write_enable (spi_write_en),
      .read_data    (spi_rdata),
      .done         (spi_done),
      .spi_clk      (spi_clk),
      .spi_cs_n     (spi_cs_n),
      .spi_mosi     (spi_mosi),
      .spi_miso     (spi_miso)
  );

  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n) begin
      state         <= ST_IDLE;
      req_ready     <= 1'b1;
      latched_write <= 1'b0;
      latched_addr  <= 16'd0;
      latched_wdata <= 32'd0;
      rdata         <= 32'd0;
      spi_read_en   <= 1'b0;
      spi_write_en  <= 1'b0;
      spi_addr      <= 16'd0;
      spi_wdata     <= 32'd0;
    end else begin
      spi_read_en  <= 1'b0;
      spi_write_en <= 1'b0;

      case (state)

        ST_IDLE:
        begin
          if (read_en || write_en)
          begin
            latched_addr  <= addr;
            latched_wdata <= wdata;
            latched_write <= write_en;
            req_ready     <= 1'b0;
            state         <= ST_START;
          end else begin
            req_ready <= 1'b1;
          end
        end

        ST_START:
        begin
          spi_addr  <= latched_addr;
          spi_wdata <= latched_wdata;
          if (latched_write) spi_write_en <= 1'b1;
          else spi_read_en <= 1'b1;
          state <= ST_WAIT;
        end

        ST_WAIT:
        begin
          if (spi_done)
          begin
            if (!latched_write) rdata <= spi_rdata;
            state <= ST_DONE;
          end
        end

        ST_DONE:
        begin
          req_ready <= 1'b1;
          state     <= ST_IDLE;
        end

        default:
          state <= ST_IDLE;

      endcase
    end
  end

endmodule
