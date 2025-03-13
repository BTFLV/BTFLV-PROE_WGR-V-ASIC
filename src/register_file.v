`default_nettype none

module register_file (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        we,
    input  wire [ 4:0] rd,
    input  wire [ 4:0] rs1,
    input  wire [ 4:0] rs2,
    input  wire [31:0] rd_data,
    output wire [31:0] rs1_data,
    output wire [31:0] rs2_data
);

  reg [31:0] registers[15:1];

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      registers[1]  <= 32'd0;
      registers[2]  <= 32'd0;
      registers[3]  <= 32'd0;
      registers[4]  <= 32'd0;
      registers[5]  <= 32'd0;
      registers[6]  <= 32'd0;
      registers[7]  <= 32'd0;
      registers[8]  <= 32'd0;
      registers[9]  <= 32'd0;
      registers[10] <= 32'd0;
      registers[11] <= 32'd0;
      registers[12] <= 32'd0;
      registers[13] <= 32'd0;
      registers[14] <= 32'd0;
      registers[15] <= 32'd0;
    end else if (we && (rd != 5'd0) && (rd < 5'd16))
    begin
      registers[rd] <= rd_data;
    end
  end

  wire rs1_valid = (rs1 != 5'd0) && (rs1 < 5'd16);
  wire rs2_valid = (rs2 != 5'd0) && (rs2 < 5'd16);

  assign rs1_data = rs1_valid ? registers[rs1] : 32'd0;
  assign rs2_data = rs2_valid ? registers[rs2] : 32'd0;

endmodule
