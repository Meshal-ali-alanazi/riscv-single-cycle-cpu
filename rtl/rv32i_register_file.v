module rv32i_register_file (
    input  wire        clk,
    input  wire        reset,
    input  wire        write_enable,
    input  wire [4:0]  rs1_addr,
    input  wire [4:0]  rs2_addr,
    input  wire [4:0]  rd_addr,
    input  wire [31:0] write_data,
    input  wire [4:0]  init_reg_addr,
    input  wire [31:0] init_reg_data,
    input  wire        init_reg_enable,
    output wire [31:0] rs1_data,
    output wire [31:0] rs2_data
);

    reg [31:0] registers [0:31];
    integer i;

    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            registers[i] = 32'h0;
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] = 32'h0;
            end
        end else if (init_reg_enable) begin
            if (init_reg_addr != 5'd0) begin
                registers[init_reg_addr] <= init_reg_data;
            end
        end else if (write_enable && (rd_addr != 5'd0)) begin
            registers[rd_addr] <= write_data;
        end
    end

    assign rs1_data = (rs1_addr == 5'd0) ? 32'd0 : registers[rs1_addr];
    assign rs2_data = (rs2_addr == 5'd0) ? 32'd0 : registers[rs2_addr];

endmodule
