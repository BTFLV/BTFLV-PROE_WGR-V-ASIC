`default_nettype none

module mb85rs64v (
    input  wire rst_n,
    input  wire clk,
    input  wire cs,
    input  wire spi_sck,
    input  wire mosi,
    output reg  miso
);

  reg [7:0] memory[0:8191];

  localparam OP_WRITE = 8'h02;
  localparam OP_READ = 8'h03;
  localparam OP_WREN = 8'h06;

  localparam STATE_OPCODE      = 2'd0,
				 STATE_ADDR        = 2'd1,
				 STATE_WRITE_DATA  = 2'd2,
				 STATE_READ_DATA   = 2'd3;

  reg [ 1:0] state;
  reg [ 7:0] opcode;

  reg [ 7:0] opcode_shift;
  reg [15:0] addr_shift;
  reg [ 7:0] data_shift;
  reg [ 3:0] bit_cnt_rx;

  reg [15:0] addr;

  reg [ 7:0] tx_reg;
  reg [ 3:0] bit_cnt_tx;

  reg        wel;

  reg [ 3:0] debug_cnt;

  reg        spi_sck_prev;
  reg        cs_prev;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state        <= STATE_OPCODE;
      opcode       <= 8'd0;
      opcode_shift <= 8'd0;
      addr_shift   <= 16'd0;
      data_shift   <= 8'd0;
      bit_cnt_rx   <= 4'd0;
      bit_cnt_tx   <= 4'd0;
      tx_reg       <= 8'd0;
      wel          <= 1'b0;
      debug_cnt    <= 4'd0;
      miso         <= 1'b0;
      spi_sck_prev <= 1'b0;
      cs_prev      <= 1'b1;
      addr         <= 16'd0;
    end else begin
      spi_sck_prev <= spi_sck;
      cs_prev      <= cs;

      if (cs) begin
        state        <= STATE_OPCODE;
        bit_cnt_rx   <= 4'd0;
        bit_cnt_tx   <= 4'd0;
        opcode_shift <= 8'd0;
        addr_shift   <= 16'd0;
        data_shift   <= 8'd0;
        addr         <= 16'd0;
        if (opcode == OP_WRITE) wel <= 1'b0;
      end else begin
        if (spi_sck && !spi_sck_prev) begin
          case (state)
            STATE_OPCODE: begin
              opcode_shift <= {opcode_shift[6:0], mosi};
              bit_cnt_rx   <= bit_cnt_rx + 1;
              if (bit_cnt_rx == 4'd7) begin
                opcode       <= {opcode_shift[6:0], mosi};
                bit_cnt_rx   <= 4'd0;
                opcode_shift <= 8'd0;
                if ({opcode_shift[6:0], mosi} == OP_WREN) wel <= 1'b1;
                else state <= STATE_ADDR;
              end
            end

            STATE_ADDR: begin
              addr_shift <= {addr_shift[14:0], mosi};
              bit_cnt_rx <= bit_cnt_rx + 1;

              if (bit_cnt_rx == 4'd15) begin
                tx_reg     <= memory[{addr_shift[14:0], mosi}];
                addr       <= {addr_shift[14:0], mosi};
                bit_cnt_rx <= 4'd0;
                if (opcode == OP_READ) begin
                  state      <= STATE_READ_DATA;
                  bit_cnt_tx <= 4'd0;
                  miso       <= memory[{addr_shift[14:0], mosi}][7];
                end else if (opcode == OP_WRITE) begin
                  if (wel) begin
                    state <= STATE_WRITE_DATA;
                  end else state <= STATE_OPCODE;
                end else begin
                  state <= STATE_OPCODE;
                end
              end
            end

            STATE_WRITE_DATA: begin
              if (bit_cnt_rx == 4'd7) begin
                memory[(addr[12:0])] <= {data_shift[6:0], mosi};
                bit_cnt_rx           <= 4'd0;
                data_shift           <= 8'd0;
                addr                 <= addr + 1;
              end else begin
                data_shift <= {data_shift[6:0], mosi};
                bit_cnt_rx <= bit_cnt_rx + 1;
              end
            end

            STATE_READ_DATA: begin
              if (bit_cnt_tx == 4'd7) begin
                bit_cnt_tx <= 4'd0;
                addr    <= addr + 1;
                tx_reg  <= memory[addr + 1];
                miso    <= memory[(addr + 1)][7];
              end else begin
                miso       <= tx_reg[6];
                tx_reg     <= {tx_reg[6:0], 1'b0};
                bit_cnt_tx <= bit_cnt_tx + 1;
              end
            end

            default: state <= STATE_OPCODE;
          endcase
        end

        debug_cnt <= (debug_cnt < 4'd15) ? (debug_cnt + 1) : 4'd0;
      end
    end
  end

endmodule
