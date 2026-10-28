module rv32i_alu (
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [2:0]  alu_op,
    output logic [31:0] result
);
    localparam ALU_ADD = 3'd0;
    localparam ALU_SUB = 3'd1;
    localparam ALU_AND = 3'd2;
    localparam ALU_OR  = 3'd3;
    localparam ALU_XOR = 3'd4;

    always_comb begin
        case (alu_op)
            ALU_ADD: result = a + b;
            ALU_SUB: result = a - b;
            ALU_AND: result = a & b;
            ALU_OR:  result = a | b;
            ALU_XOR: result = a ^ b;
            default: result = 32'b0;
        endcase
    end
endmodule
