module rv32i_control_unit (
    input  wire [6:0] opcode,
    output reg        branch,
    output reg        jump,
    output reg        mem_read,
    output reg        mem_to_reg,
    output reg [1:0]  alu_op,
    output reg        mem_write,
    output reg        alu_src,
    output reg        reg_write
);

    always @(*) begin
        branch     = 1'b0;
        jump       = 1'b0;
        mem_read   = 1'b0;
        mem_to_reg = 1'b0;
        alu_op     = 2'b00;
        mem_write  = 1'b0;
        alu_src    = 1'b0;
        reg_write  = 1'b0;

        case (opcode)
            7'b0110011: begin
                alu_op    = 2'b10;
                reg_write = 1'b1;
            end

            7'b0010011: begin
                alu_op    = 2'b11;
                alu_src   = 1'b1;
                reg_write = 1'b1;
            end

            7'b0000011: begin
                mem_read   = 1'b1;
                mem_to_reg = 1'b1;
                alu_src    = 1'b1;
                reg_write  = 1'b1;
            end

            7'b0100011: begin
                mem_write = 1'b1;
                alu_src   = 1'b1;
            end

            7'b1100011: begin
                branch = 1'b1;
                alu_op = 2'b01;
            end

            7'b0110111: begin
                alu_src   = 1'b1;
                reg_write = 1'b1;
            end

            7'b0010111: begin
                alu_src   = 1'b1;
                reg_write = 1'b1;
            end

            7'b1101111: begin
                jump      = 1'b1;
                alu_src   = 1'b1;
                reg_write = 1'b1;
            end

            7'b1100111: begin
                jump      = 1'b1;
                alu_src   = 1'b1;
                reg_write = 1'b1;
            end

            default: begin
            end
        endcase
    end

endmodule
