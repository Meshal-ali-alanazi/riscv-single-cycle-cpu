module rv32i_execute_memory (
    input  wire        clk,
    input  wire        reset,
    input  wire [31:0] rs1_data,
    input  wire [31:0] rs2_data,
    input  wire [31:0] imm_in,
    input  wire [31:0] pc_in,
    input  wire [6:0]  opcode,
    input  wire [2:0]  funct3,
    input  wire [6:0]  funct7,
    input  wire [1:0]  alu_op,
    input  wire        alu_src,
    input  wire        mem_write,
    input  wire        mem_read,
    input  wire        mem_to_reg,
    input  wire        branch,
    input  wire        jump,
    output reg  [31:0] alu_result,
    output reg  [31:0] mem_rdata,
    output reg  [31:0] write_data,
    output reg         zero_flag,
    output reg         branch_taken,
    output reg  [31:0] branch_target
);

    reg [31:0] data_mem [0:1023];
    integer i;

    wire [31:0] alu_in1 = rs1_data;
    wire [31:0] alu_in2 = alu_src ? imm_in : rs2_data;
    wire [4:0] shamt = alu_in2[4:0];

    reg [31:0] alu_out;

    initial begin
        for (i = 0; i < 1024; i = i + 1) begin
            data_mem[i] = 32'h0;
        end
    end

    always @(*) begin
        alu_out = 32'h0;

        case (alu_op)
            2'b00: begin
                if (opcode == 7'b0110111) begin
                    alu_out = imm_in;
                end else if (opcode == 7'b0010111) begin
                    alu_out = pc_in + imm_in;
                end else begin
                    alu_out = alu_in1 + alu_in2;
                end
            end

            2'b01: begin
                alu_out = alu_in1 - alu_in2;
            end

            2'b10: begin
                case (funct3)
                    3'b000: alu_out = funct7[5] ? (alu_in1 - alu_in2) : (alu_in1 + alu_in2);
                    3'b001: alu_out = alu_in1 << shamt;
                    3'b010: alu_out = ($signed(alu_in1) < $signed(alu_in2)) ? 32'd1 : 32'd0;
                    3'b011: alu_out = (alu_in1 < alu_in2) ? 32'd1 : 32'd0;
                    3'b100: alu_out = alu_in1 ^ alu_in2;
                    3'b101: alu_out = funct7[5] ? ($signed(alu_in1) >>> shamt) : (alu_in1 >> shamt);
                    3'b110: alu_out = alu_in1 | alu_in2;
                    3'b111: alu_out = alu_in1 & alu_in2;
                    default: alu_out = 32'h0;
                endcase
            end

            2'b11: begin
                case (funct3)
                    3'b000: alu_out = alu_in1 + alu_in2;
                    3'b001: alu_out = alu_in1 << shamt;
                    3'b010: alu_out = ($signed(alu_in1) < $signed(alu_in2)) ? 32'd1 : 32'd0;
                    3'b011: alu_out = (alu_in1 < alu_in2) ? 32'd1 : 32'd0;
                    3'b100: alu_out = alu_in1 ^ alu_in2;
                    3'b101: alu_out = imm_in[10] ? ($signed(alu_in1) >>> shamt) : (alu_in1 >> shamt);
                    3'b110: alu_out = alu_in1 | alu_in2;
                    3'b111: alu_out = alu_in1 & alu_in2;
                    default: alu_out = 32'h0;
                endcase
            end

            default: alu_out = alu_in1 + alu_in2;
        endcase
    end

    always @(*) begin
        alu_result = alu_out;
        zero_flag = (alu_out == 32'h0);
    end

    always @(*) begin
        branch_taken = 1'b0;
        branch_target = pc_in + 4;

        if (jump) begin
            if (opcode == 7'b1101111) begin
                branch_taken = 1'b1;
                branch_target = pc_in + imm_in;
            end else if (opcode == 7'b1100111) begin
                branch_taken = 1'b1;
                branch_target = (rs1_data + imm_in) & 32'hFFFFFFFE;
            end
        end else if (branch) begin
            case (funct3)
                3'b000: branch_taken = (rs1_data == rs2_data);
                3'b001: branch_taken = (rs1_data != rs2_data);
                3'b100: branch_taken = ($signed(rs1_data) < $signed(rs2_data));
                3'b101: branch_taken = ($signed(rs1_data) >= $signed(rs2_data));
                3'b110: branch_taken = (rs1_data < rs2_data);
                3'b111: branch_taken = (rs1_data >= rs2_data);
                default: branch_taken = 1'b0;
            endcase

            if (branch_taken) begin
                branch_target = pc_in + imm_in;
            end
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 1024; i = i + 1) begin
                data_mem[i] = 32'h0;
            end
        end else if (mem_write) begin
            case (funct3)
                3'b000: begin
                    case (alu_out[1:0])
                        2'b00: data_mem[alu_out[11:2]] <= {data_mem[alu_out[11:2]][31:8], rs2_data[7:0]};
                        2'b01: data_mem[alu_out[11:2]] <= {data_mem[alu_out[11:2]][31:16], rs2_data[7:0], data_mem[alu_out[11:2]][7:0]};
                        2'b10: data_mem[alu_out[11:2]] <= {data_mem[alu_out[11:2]][31:24], rs2_data[7:0], data_mem[alu_out[11:2]][15:0]};
                        2'b11: data_mem[alu_out[11:2]] <= {rs2_data[7:0], data_mem[alu_out[11:2]][23:0]};
                    endcase
                end

                3'b001: begin
                    if (alu_out[1] == 1'b0) begin
                        data_mem[alu_out[11:2]] <= {data_mem[alu_out[11:2]][31:16], rs2_data[15:0]};
                    end else begin
                        data_mem[alu_out[11:2]] <= {rs2_data[15:0], data_mem[alu_out[11:2]][15:0]};
                    end
                end

                3'b010: begin
                    data_mem[alu_out[11:2]] <= rs2_data;
                end

                default: begin
                    data_mem[alu_out[11:2]] <= rs2_data;
                end
            endcase
        end
    end

    always @(*) begin
        if (!mem_read) begin
            mem_rdata = 32'h0;
        end else begin
            case (funct3)
                3'b000: begin
                    case (alu_out[1:0])
                        2'b00: mem_rdata = {{24{data_mem[alu_out[11:2]][7]}}, data_mem[alu_out[11:2]][7:0]};
                        2'b01: mem_rdata = {{24{data_mem[alu_out[11:2]][15]}}, data_mem[alu_out[11:2]][15:8]};
                        2'b10: mem_rdata = {{24{data_mem[alu_out[11:2]][23]}}, data_mem[alu_out[11:2]][23:16]};
                        2'b11: mem_rdata = {{24{data_mem[alu_out[11:2]][31]}}, data_mem[alu_out[11:2]][31:24]};
                    endcase
                end

                3'b001: begin
                    if (alu_out[1] == 1'b0) begin
                        mem_rdata = {{16{data_mem[alu_out[11:2]][15]}}, data_mem[alu_out[11:2]][15:0]};
                    end else begin
                        mem_rdata = {{16{data_mem[alu_out[11:2]][31]}}, data_mem[alu_out[11:2]][31:16]};
                    end
                end

                3'b010: begin
                    mem_rdata = data_mem[alu_out[11:2]];
                end

                3'b100: begin
                    case (alu_out[1:0])
                        2'b00: mem_rdata = {24'h0, data_mem[alu_out[11:2]][7:0]};
                        2'b01: mem_rdata = {24'h0, data_mem[alu_out[11:2]][15:8]};
                        2'b10: mem_rdata = {24'h0, data_mem[alu_out[11:2]][23:16]};
                        2'b11: mem_rdata = {24'h0, data_mem[alu_out[11:2]][31:24]};
                    endcase
                end

                3'b101: begin
                    if (alu_out[1] == 1'b0) begin
                        mem_rdata = {16'h0, data_mem[alu_out[11:2]][15:0]};
                    end else begin
                        mem_rdata = {16'h0, data_mem[alu_out[11:2]][31:16]};
                    end
                end

                default: begin
                    mem_rdata = data_mem[alu_out[11:2]];
                end
            endcase
        end
    end

    always @(*) begin
        if ((opcode == 7'b1101111) || (opcode == 7'b1100111)) begin
            write_data = pc_in + 4;
        end else if (mem_to_reg) begin
            write_data = mem_rdata;
        end else begin
            write_data = alu_result;
        end
    end

endmodule
