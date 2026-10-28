module pipelined_cpu (
    input logic clk,
    input logic reset
);
    localparam OP_ADD  = 3'd0;
    localparam OP_SUB  = 3'd1;
    localparam OP_AND  = 3'd2;
    localparam OP_OR   = 3'd3;
    localparam OP_XOR  = 3'd4;
    localparam OP_ADDI = 3'd5;

    logic [31:0] regs [0:31];
    logic [31:0] imem [0:31];
    logic [31:0] pc;

    // IF/ID pipeline register
    logic [31:0] ifid_instr, ifid_pc;
    // ID/EX pipeline register
    logic [31:0] idex_pc, idex_rs1_val, idex_rs2_val, idex_imm;
    logic [4:0] idex_rd;
    logic [2:0] idex_op;
    logic idex_regwrite, idex_use_imm;
    // EX/MEM pipeline register
    logic [31:0] exmem_result;
    logic [4:0] exmem_rd;
    logic exmem_regwrite;
    // MEM/WB pipeline register
    logic [31:0] memwb_result;
    logic [4:0] memwb_rd;
    logic memwb_regwrite;

    logic [31:0] alu_b, alu_result;
    logic [2:0] decoded_op;
    logic decoded_regwrite, decoded_use_imm;
    logic [31:0] decoded_imm;

    rv32i_alu alu(.a(idex_rs1_val), .b(alu_b), .alu_op(idex_op), .result(alu_result));

    always_comb begin
        alu_b = idex_use_imm ? idex_imm : idex_rs2_val;
        decoded_op = OP_ADD;
        decoded_regwrite = 1'b0;
        decoded_use_imm = 1'b0;
        decoded_imm = {{20{ifid_instr[31]}}, ifid_instr[31:20]};

        case (ifid_instr[6:0])
            7'b0010011: begin // OP-IMM: ADDI subset only
                decoded_op = OP_ADDI;
                decoded_regwrite = 1'b1;
                decoded_use_imm = 1'b1;
            end
            7'b0110011: begin // OP: ADD/SUB/AND/OR/XOR
                decoded_regwrite = 1'b1;
                case ({ifid_instr[31:25], ifid_instr[14:12]})
                    {7'b0000000,3'b000}: decoded_op = OP_ADD;
                    {7'b0100000,3'b000}: decoded_op = OP_SUB;
                    {7'b0000000,3'b111}: decoded_op = OP_AND;
                    {7'b0000000,3'b110}: decoded_op = OP_OR;
                    {7'b0000000,3'b100}: decoded_op = OP_XOR;
                    default: begin decoded_op = OP_ADD; decoded_regwrite = 1'b0; end
                endcase
            end
            default: begin decoded_op = OP_ADD; decoded_regwrite = 1'b0; end
        endcase
    end

    integer i;
    always_ff @(posedge clk) begin
        if (reset) begin
            pc <= 0;
            ifid_instr <= 32'h00000013; // NOP
            ifid_pc <= 0;
            idex_pc <= 0; idex_rs1_val <= 0; idex_rs2_val <= 0; idex_imm <= 0;
            idex_rd <= 0; idex_op <= OP_ADD; idex_regwrite <= 0; idex_use_imm <= 0;
            exmem_result <= 0; exmem_rd <= 0; exmem_regwrite <= 0;
            memwb_result <= 0; memwb_rd <= 0; memwb_regwrite <= 0;
            for (i = 0; i < 32; i = i + 1) regs[i] <= 0;
        end else begin
            // WB
            if (memwb_regwrite && memwb_rd != 0)
                regs[memwb_rd] <= memwb_result;
            regs[0] <= 0;

            // MEM/WB
            memwb_result <= exmem_result;
            memwb_rd <= exmem_rd;
            memwb_regwrite <= exmem_regwrite;

            // EX/MEM
            exmem_result <= alu_result;
            exmem_rd <= idex_rd;
            exmem_regwrite <= idex_regwrite;

            // ID/EX
            idex_pc <= ifid_pc;
            idex_rs1_val <= (ifid_instr[19:15] == 0) ? 0 : regs[ifid_instr[19:15]];
            idex_rs2_val <= (ifid_instr[24:20] == 0) ? 0 : regs[ifid_instr[24:20]];
            idex_imm <= decoded_imm;
            idex_rd <= ifid_instr[11:7];
            idex_op <= (decoded_op == OP_ADDI) ? 3'd0 : decoded_op;
            idex_regwrite <= decoded_regwrite;
            idex_use_imm <= decoded_use_imm;

            // IF/ID and PC
            ifid_instr <= imem[pc[6:2]];
            ifid_pc <= pc;
            pc <= pc + 4;
        end
    end

    // Testbench loads instruction memory hierarchically for this starter.
endmodule
