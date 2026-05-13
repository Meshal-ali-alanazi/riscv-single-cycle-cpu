module rv32i_instruction_fetch (
    input  wire        clk,
    input  wire        reset,
    input  wire [31:0] instruction_in,
    input  wire [9:0]  instr_addr,
    input  wire        load_instr,
    input  wire        branch_taken,
    input  wire [31:0] branch_target,
    input  wire        pc_enable,
    output reg  [31:0] pc,
    output wire [31:0] instruction
);

    reg [31:0] instruction_mem [0:1023];
    integer i;

    initial begin
        for (i = 0; i < 1024; i = i + 1) begin
            instruction_mem[i] = 32'h00000013;
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            pc <= 32'h0;
        end else begin
            if (load_instr) begin
                instruction_mem[instr_addr] <= instruction_in;
            end else if (pc_enable) begin
                if (branch_taken) begin
                    pc <= branch_target;
                end else begin
                    pc <= pc + 4;
                end
            end
        end
    end

    assign instruction = instruction_mem[pc[11:2]];

endmodule
