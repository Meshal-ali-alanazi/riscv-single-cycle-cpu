`timescale 1ns / 1ps

module tb_rv32i_single_cycle_cpu;

    parameter PERIOD = 10;

    reg         clk;
    reg         reset;
    reg [31:0]  instruction_in;
    reg [9:0]   instr_addr;
    reg         load_instr;
    reg [4:0]   init_reg_addr;
    reg [31:0]  init_reg_data;
    reg         init_reg_enable;

    wire [31:0] pc;
    wire [31:0] instruction;
    wire [31:0] rs1_data;
    wire [31:0] rs2_data;
    wire [31:0] imm_out;
    wire [31:0] alu_result;
    wire [31:0] mem_rdata;
    wire [31:0] write_data;
    wire        branch_taken;
    wire [31:0] branch_target;
    wire        mem_read;
    wire        mem_write;

    integer checks_total;
    integer checks_failed;

    rv32i_single_cycle_cpu uut (
        .clk(clk),
        .reset(reset),
        .instruction_in(instruction_in),
        .instr_addr(instr_addr),
        .load_instr(load_instr),
        .init_reg_addr(init_reg_addr),
        .init_reg_data(init_reg_data),
        .init_reg_enable(init_reg_enable),
        .pc(pc),
        .instruction(instruction),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .imm_out(imm_out),
        .alu_result(alu_result),
        .mem_rdata(mem_rdata),
        .write_data(write_data),
        .branch_taken(branch_taken),
        .branch_target(branch_target),
        .mem_read(mem_read),
        .mem_write(mem_write)
    );

    initial begin
        clk = 1'b0;
        forever #(PERIOD / 2) clk = ~clk;
    end

    function [31:0] enc_r;
        input [6:0] funct7;
        input [4:0] rs2;
        input [4:0] rs1;
        input [2:0] funct3;
        input [4:0] rd;
        input [6:0] opcode;
        begin
            enc_r = {funct7, rs2, rs1, funct3, rd, opcode};
        end
    endfunction

    function [31:0] enc_i;
        input integer imm;
        input [4:0] rs1;
        input [2:0] funct3;
        input [4:0] rd;
        input [6:0] opcode;
        reg [11:0] imm12;
        begin
            imm12 = imm[11:0];
            enc_i = {imm12, rs1, funct3, rd, opcode};
        end
    endfunction

    function [31:0] enc_s;
        input integer imm;
        input [4:0] rs2;
        input [4:0] rs1;
        input [2:0] funct3;
        input [6:0] opcode;
        reg [11:0] imm12;
        begin
            imm12 = imm[11:0];
            enc_s = {imm12[11:5], rs2, rs1, funct3, imm12[4:0], opcode};
        end
    endfunction

    function [31:0] enc_b;
        input integer imm;
        input [4:0] rs2;
        input [4:0] rs1;
        input [2:0] funct3;
        input [6:0] opcode;
        reg [12:0] imm13;
        begin
            imm13 = imm[12:0];
            enc_b = {imm13[12], imm13[10:5], rs2, rs1, funct3, imm13[4:1], imm13[11], opcode};
        end
    endfunction

    function [31:0] enc_u;
        input [19:0] imm20;
        input [4:0]  rd;
        input [6:0]  opcode;
        begin
            enc_u = {imm20, rd, opcode};
        end
    endfunction

    function [31:0] enc_j;
        input integer imm;
        input [4:0] rd;
        input [6:0] opcode;
        reg [20:0] imm21;
        begin
            imm21 = imm[20:0];
            enc_j = {imm21[20], imm21[10:1], imm21[11], imm21[19:12], rd, opcode};
        end
    endfunction

    localparam [6:0] OP_R     = 7'b0110011;
    localparam [6:0] OP_I     = 7'b0010011;
    localparam [6:0] OP_L     = 7'b0000011;
    localparam [6:0] OP_S     = 7'b0100011;
    localparam [6:0] OP_B     = 7'b1100011;
    localparam [6:0] OP_LUI   = 7'b0110111;
    localparam [6:0] OP_AUIPC = 7'b0010111;
    localparam [6:0] OP_JAL   = 7'b1101111;
    localparam [6:0] OP_JALR  = 7'b1100111;

    task run_cycles;
        input integer cycles;
        integer idx;
        begin
            for (idx = 0; idx < cycles; idx = idx + 1) begin
                @(posedge clk);
            end
        end
    endtask

    task load_instruction;
        input [9:0] addr;
        input [31:0] data;
        begin
            instr_addr = addr;
            instruction_in = data;
            @(posedge clk);
        end
    endtask

    task clear_imem;
        input integer words;
        integer idx;
        begin
            for (idx = 0; idx < words; idx = idx + 1) begin
                load_instruction(idx[9:0], 32'h00000013);
            end
        end
    endtask

    task reset_core;
        begin
            reset = 1'b1;
            load_instr = 1'b0;
            init_reg_enable = 1'b0;
            init_reg_addr = 5'd0;
            init_reg_data = 32'd0;
            instr_addr = 10'd0;
            instruction_in = 32'd0;
            run_cycles(2);
            reset = 1'b0;
        end
    endtask

    task expect_reg;
        input [4:0] reg_idx;
        input [31:0] expected;
        input [511:0] label;
        reg [31:0] actual;
        begin
            actual = uut.decode_stage.register_file.registers[reg_idx];
            checks_total = checks_total + 1;
            if (actual !== expected) begin
                checks_failed = checks_failed + 1;
                $display("FAIL: %0s - x%0d = 0x%08h, expected 0x%08h",
                         label, reg_idx, actual, expected);
            end else begin
                $display("PASS: %0s", label);
            end
        end
    endtask

    task expect_mem_word;
        input [9:0] word_addr;
        input [31:0] expected;
        input [511:0] label;
        reg [31:0] actual;
        begin
            actual = uut.execute_stage.data_mem[word_addr];
            checks_total = checks_total + 1;
            if (actual !== expected) begin
                checks_failed = checks_failed + 1;
                $display("FAIL: %0s - mem[%0d] = 0x%08h, expected 0x%08h",
                         label, word_addr, actual, expected);
            end else begin
                $display("PASS: %0s", label);
            end
        end
    endtask

    initial begin
        $dumpfile("sim/output/rv32i_single_cycle_cpu_wave.vcd");
        $dumpvars(0, tb_rv32i_single_cycle_cpu);

        checks_total = 0;
        checks_failed = 0;
        reset = 1'b1;
        load_instr = 1'b0;
        init_reg_enable = 1'b0;
        init_reg_addr = 5'd0;
        init_reg_data = 32'd0;
        instr_addr = 10'd0;
        instruction_in = 32'd0;

        reset_core();

        $display("=== Single-cycle Test 1: sum loop ===");
        load_instr = 1'b1;
        clear_imem(64);
        load_instruction(10'd0, 32'h00000093); // addi x1, x0, 0
        load_instruction(10'd1, 32'h00a00113); // addi x2, x0, 10
        load_instruction(10'd2, 32'h002080b3); // add  x1, x1, x2
        load_instruction(10'd3, 32'hfff10113); // addi x2, x2, -1
        load_instruction(10'd4, 32'hfe011ce3); // bne  x2, x0, -8
        load_instruction(10'd5, 32'h00000013); // nop
        load_instr = 1'b0;
        run_cycles(120);
        expect_reg(5'd1, 32'd55, "sum 1 to 10");
        expect_reg(5'd2, 32'd0, "loop counter reaches zero");
        $display("INFO: test 1 final PC = 0x%08h", pc);

        $display("=== Single-cycle Test 2: RV32I datapath/control ===");
        reset_core();
        load_instr = 1'b1;
        clear_imem(64);
        load_instruction(10'd0,  enc_u(20'h12345, 5'd3, OP_LUI));                    // lui x3, 0x12345
        load_instruction(10'd1,  enc_u(20'h00001, 5'd4, OP_AUIPC));                  // auipc x4, 0x1
        load_instruction(10'd2,  enc_i(5, 5'd0, 3'b000, 5'd5, OP_I));                // addi x5, x0, 5
        load_instruction(10'd3,  enc_i(2, 5'd5, 3'b001, 5'd6, OP_I));                // slli x6, x5, 2
        load_instruction(10'd4,  enc_r(7'b0000000, 5'd5, 5'd6, 3'b110, 5'd7, OP_R)); // or x7, x6, x5
        load_instruction(10'd5,  enc_i(15, 5'd7, 3'b111, 5'd8, OP_I));               // andi x8, x7, 15
        load_instruction(10'd6,  enc_i(10, 5'd8, 3'b100, 5'd9, OP_I));               // xori x9, x8, 10
        load_instruction(10'd7,  enc_r(7'b0000000, 5'd6, 5'd5, 3'b010, 5'd10, OP_R)); // slt x10, x5, x6
        load_instruction(10'd8,  enc_r(7'b0000000, 5'd5, 5'd6, 3'b011, 5'd11, OP_R)); // sltu x11, x6, x5
        load_instruction(10'd9,  enc_s(0, 5'd7, 5'd0, 3'b010, OP_S));                // sw x7, 0(x0)
        load_instruction(10'd10, enc_i(0, 5'd0, 3'b010, 5'd12, OP_L));               // lw x12, 0(x0)
        load_instruction(10'd11, enc_b(8, 5'd7, 5'd12, 3'b000, OP_B));               // beq x12, x7, +8
        load_instruction(10'd12, enc_i(1, 5'd0, 3'b000, 5'd13, OP_I));               // skipped
        load_instruction(10'd13, enc_i(2, 5'd0, 3'b000, 5'd13, OP_I));               // branch target
        load_instruction(10'd14, enc_j(8, 5'd14, OP_JAL));                          // jal x14, +8
        load_instruction(10'd15, enc_i(1, 5'd0, 3'b000, 5'd15, OP_I));               // skipped
        load_instruction(10'd16, enc_i(3, 5'd0, 3'b000, 5'd15, OP_I));               // jal target
        load_instruction(10'd17, 32'h00000013);                                      // nop
        load_instr = 1'b0;
        run_cycles(160);
        expect_reg(5'd3,  32'h12345000, "LUI");
        expect_reg(5'd4,  32'h00001004, "AUIPC");
        expect_reg(5'd5,  32'd5, "ADDI");
        expect_reg(5'd6,  32'd20, "SLLI");
        expect_reg(5'd7,  32'd21, "OR");
        expect_reg(5'd8,  32'd5, "ANDI");
        expect_reg(5'd9,  32'd15, "XORI");
        expect_reg(5'd10, 32'd1, "SLT");
        expect_reg(5'd11, 32'd0, "SLTU");
        expect_reg(5'd12, 32'd21, "LW");
        expect_reg(5'd13, 32'd2, "BEQ taken path");
        expect_reg(5'd14, 32'h0000003c, "JAL return address");
        expect_reg(5'd15, 32'd3, "JAL target");
        expect_mem_word(10'd0, 32'd21, "SW writes memory");

        $display("=== Single-cycle Test 3: byte and halfword memory ===");
        reset_core();
        load_instr = 1'b1;
        clear_imem(64);
        load_instruction(10'd0,  enc_i(8'h80, 5'd0, 3'b000, 5'd1, OP_I));       // addi x1, x0, 0x80
        load_instruction(10'd1,  enc_s(0, 5'd1, 5'd0, 3'b000, OP_S));           // sb x1, 0(x0)
        load_instruction(10'd2,  enc_i(0, 5'd0, 3'b000, 5'd2, OP_L));           // lb x2, 0(x0)
        load_instruction(10'd3,  enc_u(20'h00008, 5'd3, OP_LUI));               // lui x3, 0x8
        load_instruction(10'd4,  enc_i(1, 5'd3, 3'b000, 5'd3, OP_I));           // addi x3, x3, 1
        load_instruction(10'd5,  enc_s(2, 5'd3, 5'd0, 3'b001, OP_S));           // sh x3, 2(x0)
        load_instruction(10'd6,  enc_i(2, 5'd0, 3'b001, 5'd4, OP_L));           // lh x4, 2(x0)
        load_instruction(10'd7,  enc_u(20'h11223, 5'd5, OP_LUI));               // lui x5, 0x11223
        load_instruction(10'd8,  enc_i(12'h344, 5'd5, 3'b000, 5'd5, OP_I));     // addi x5, x5, 0x344
        load_instruction(10'd9,  enc_s(4, 5'd5, 5'd0, 3'b010, OP_S));           // sw x5, 4(x0)
        load_instruction(10'd10, enc_i(8'hAA, 5'd0, 3'b000, 5'd6, OP_I));       // addi x6, x0, 0xAA
        load_instruction(10'd11, enc_s(5, 5'd6, 5'd0, 3'b000, OP_S));           // sb x6, 5(x0)
        load_instruction(10'd12, enc_i(4, 5'd0, 3'b010, 5'd7, OP_L));           // lw x7, 4(x0)
        load_instruction(10'd13, enc_i(8'h55, 5'd0, 3'b000, 5'd8, OP_I));       // addi x8, x0, 0x55
        load_instruction(10'd14, enc_i(8, 5'd8, 3'b001, 5'd8, OP_I));           // slli x8, x8, 8
        load_instruction(10'd15, enc_i(8'hAA, 5'd8, 3'b000, 5'd8, OP_I));       // addi x8, x8, 0xAA
        load_instruction(10'd16, enc_s(6, 5'd8, 5'd0, 3'b001, OP_S));           // sh x8, 6(x0)
        load_instruction(10'd17, enc_i(4, 5'd0, 3'b010, 5'd9, OP_L));           // lw x9, 4(x0)
        load_instr = 1'b0;
        run_cycles(120);
        expect_reg(5'd2, 32'hFFFFFF80, "LB sign extension");
        expect_reg(5'd4, 32'hFFFF8001, "LH sign extension");
        expect_reg(5'd7, 32'h1122AA44, "SB partial write");
        expect_reg(5'd9, 32'h55AAAA44, "SH partial write");

        $display("==================================================");
        $display("Single-cycle summary");
        $display("Total checks: %0d", checks_total);
        $display("Passed: %0d", checks_total - checks_failed);
        $display("Failed: %0d", checks_failed);
        $display("==================================================");

        if (checks_failed == 0) begin
            $display("PASS: tb_rv32i_single_cycle_cpu.sv");
            $finish;
        end else begin
            $fatal(1, "FAIL: tb_rv32i_single_cycle_cpu.sv - %0d check(s) failed", checks_failed);
        end
    end

endmodule
