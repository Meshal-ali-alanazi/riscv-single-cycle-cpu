module rv32i_instruction_decode (
    input  wire        clk,
    input  wire        reset,
    input  wire [31:0] instruction,
    input  wire [31:0] write_data,
    input  wire        reg_write,
    input  wire [4:0]  init_reg_addr,
    input  wire [31:0] init_reg_data,
    input  wire        init_reg_enable,
    output wire [31:0] rs1_data,
    output wire [31:0] rs2_data,
    output reg  [31:0] imm_out
);

    wire [4:0] rs1 = instruction[19:15];
    wire [4:0] rs2 = instruction[24:20];
    wire [4:0] rd = instruction[11:7];
    wire [6:0] opcode = instruction[6:0];

    wire [31:0] imm_i = {{20{instruction[31]}}, instruction[31:20]};
    wire [31:0] imm_s = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
    wire [31:0] imm_b = {{20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0};
    wire [31:0] imm_u = {instruction[31:12], 12'b0};
    wire [31:0] imm_j = {{12{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:21], 1'b0};

    always @(*) begin
        case (opcode)
            7'b0010011: imm_out = imm_i;
            7'b0000011: imm_out = imm_i;
            7'b1100111: imm_out = imm_i;
            7'b0100011: imm_out = imm_s;
            7'b1100011: imm_out = imm_b;
            7'b0110111: imm_out = imm_u;
            7'b0010111: imm_out = imm_u;
            7'b1101111: imm_out = imm_j;
            default:    imm_out = 32'h0;
        endcase
    end

    rv32i_register_file register_file (
        .clk(clk),
        .reset(reset),
        .write_enable(reg_write),
        .rs1_addr(rs1),
        .rs2_addr(rs2),
        .rd_addr(rd),
        .write_data(write_data),
        .init_reg_addr(init_reg_addr),
        .init_reg_data(init_reg_data),
        .init_reg_enable(init_reg_enable),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

endmodule
