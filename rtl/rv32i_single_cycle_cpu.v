module rv32i_single_cycle_cpu (
    input  wire        clk,
    input  wire        reset,
    input  wire [31:0] instruction_in,
    input  wire [9:0]  instr_addr,
    input  wire        load_instr,
    input  wire [4:0]  init_reg_addr,
    input  wire [31:0] init_reg_data,
    input  wire        init_reg_enable,
    output wire [31:0] pc,
    output wire [31:0] instruction,
    output wire [31:0] rs1_data,
    output wire [31:0] rs2_data,
    output wire [31:0] imm_out,
    output wire [31:0] alu_result,
    output wire [31:0] mem_rdata,
    output wire [31:0] write_data,
    output wire        branch_taken,
    output wire [31:0] branch_target,
    output wire        mem_read,
    output wire        mem_write
);

    wire [31:0] fetched_instruction;
    wire [6:0]  opcode;
    wire [2:0]  funct3;
    wire [6:0]  funct7;

    wire        branch;
    wire        jump;
    wire        mem_to_reg;
    wire [1:0]  alu_op;
    wire        alu_src;
    wire        reg_write;

    wire [31:0] rs1_val;
    wire [31:0] rs2_val;
    wire [31:0] immediate;
    wire [31:0] wb_data;
    wire        zero_flag;
    wire [31:0] alu_res;
    wire [31:0] mem_read_data;
    wire        branch_taken_internal;
    wire [31:0] branch_target_internal;

    wire pc_enable = !load_instr && !reset && !init_reg_enable;
    wire reg_write_en = reg_write && !load_instr && !reset;
    wire mem_write_en = mem_write && !load_instr && !reset;

    assign opcode = fetched_instruction[6:0];
    assign funct3 = fetched_instruction[14:12];
    assign funct7 = fetched_instruction[31:25];

    rv32i_instruction_fetch fetch_stage (
        .clk(clk),
        .reset(reset),
        .instruction_in(instruction_in),
        .instr_addr(instr_addr),
        .load_instr(load_instr),
        .branch_taken(branch_taken_internal),
        .branch_target(branch_target_internal),
        .pc_enable(pc_enable),
        .pc(pc),
        .instruction(fetched_instruction)
    );

    rv32i_control_unit control_stage (
        .opcode(opcode),
        .branch(branch),
        .jump(jump),
        .mem_read(mem_read),
        .mem_to_reg(mem_to_reg),
        .alu_op(alu_op),
        .mem_write(mem_write),
        .alu_src(alu_src),
        .reg_write(reg_write)
    );

    rv32i_instruction_decode decode_stage (
        .clk(clk),
        .reset(reset),
        .instruction(fetched_instruction),
        .write_data(wb_data),
        .reg_write(reg_write_en),
        .init_reg_addr(init_reg_addr),
        .init_reg_data(init_reg_data),
        .init_reg_enable(init_reg_enable),
        .rs1_data(rs1_val),
        .rs2_data(rs2_val),
        .imm_out(immediate)
    );

    rv32i_execute_memory execute_stage (
        .clk(clk),
        .reset(reset),
        .rs1_data(rs1_val),
        .rs2_data(rs2_val),
        .imm_in(immediate),
        .pc_in(pc),
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .alu_op(alu_op),
        .alu_src(alu_src),
        .mem_write(mem_write_en),
        .mem_read(mem_read),
        .mem_to_reg(mem_to_reg),
        .branch(branch),
        .jump(jump),
        .alu_result(alu_res),
        .mem_rdata(mem_read_data),
        .write_data(wb_data),
        .zero_flag(zero_flag),
        .branch_taken(branch_taken_internal),
        .branch_target(branch_target_internal)
    );

    assign instruction = fetched_instruction;
    assign rs1_data = rs1_val;
    assign rs2_data = rs2_val;
    assign imm_out = immediate;
    assign alu_result = alu_res;
    assign mem_rdata = mem_read_data;
    assign write_data = wb_data;
    assign branch_taken = branch_taken_internal;
    assign branch_target = branch_target_internal;

endmodule
