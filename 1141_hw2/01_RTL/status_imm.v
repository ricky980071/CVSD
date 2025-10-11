module status_imm#(
    parameter DATA_WIDTH = 32
)(
    input  [DATA_WIDTH-1:0] i_inst, // instruction
    output [DATA_WIDTH-1:0] o_imm   // immediate


    //status
    input [DATA_WIDTH-1:0] i_result,
    input i_invalid,
    input [6:0] i_opcode,
    output [2:0] o_stat
);
// opcode definition
// `define OP_SUB    7'b0110011
// `define OP_ADDI   7'b0010011
// `define OP_LW     7'b0000011
// `define OP_SW     7'b0100011
// `define OP_BEQ    7'b1100011
// `define OP_BLT    7'b1100011
// `define OP_JALR   7'b1100111
// `define OP_AUIPC  7'b0010111
// `define OP_SLT    7'b0110011
// `define OP_SRL    7'b0110011
// `define OP_FSUB   7'b1010011
// `define OP_FMUL   7'b1010011
// `define OP_FCVTWS 7'b1010011
// `define OP_FLW    7'b0000111
// `define OP_FSW    7'b0100111
// `define OP_FCLASS 7'b1010011
// `define OP_EOF    7'b1110011

// `define R_TYPE 0
// `define I_TYPE 1
// `define S_TYPE 2
// `define B_TYPE 3
// `define U_TYPE 4
// `define INVALID_TYPE 5
// `define EOF_TYPE 6
reg [2:0] r_stat;
assign o_stat = r_stat;
always @(*) begin
    if(i_in_valid) r_stat=INVALID_TYPE;
    else begin
        case(i_opcode)
            `OP_EOF: r_stat=`EOF_TYPE;
            `OP_AUIPC: r_stat=`U_TYPE;

            `OP_SUB, `OP_SLT, `OP_SRL, `OP_FSUB, `OP_FMUL, `OP_FCVTWS, `OP_FCLASS: r_stat=`R_TYPE;
            `OP_ADDI,  `OP_JALR: r_stat=`I_TYPE;

            `OP_LW, `OP_FLW:begin
                if(i_result >= 32'd4096 && i_result < 32'd8192) r_stat=`I_TYPE;
                else r_stat=`INVALID_TYPE; // load address out of bound
            end
            
            `OP_SW, `OP_FSW: begin

              if(i_result >= 32'd4096 && i_result < 32'd8192) r_stat=`I_TYPE;
              else r_stat=`INVALID_TYPE; // store address out of bound
            end
            `OP_BEQ, `OP_BLT: r_stat=`B_TYPE;
            default: r_stat=`INVALID_TYPE;
        endcase
    end

end


reg [DATA_WIDTH-1:0] r_imm;
assign o_imm = r_imm;
 always @(*) begin
        case (i_inst[6:0])
            `OP_EOF: begin
                r_imm = 0;
            end
            `OP_AUIPC: begin
                // U-type: no funct3, funct7
                r_imm = i_inst[31:12]; 
            end
            `OP_SUB, `OP_FSUB: begin
                // R-type: no r_imm (other R-type with same format)
                r_imm = 0;
            end
            `OP_ADDI, `OP_LW, `OP_JALR, `OP_FLW: begin
                // I-type: 
                r_imm = {{20{i_inst[31]}}, i_inst[31:20]}; // r_imm[11:0] with sign extension
            end
            `OP_SW, `OP_FSW: begin
                // S-type: 
                r_imm = {{20{i_inst[31]}}, i_inst[31:25], i_inst[11:7]}; // r_imm[11:5], r_imm[4:0] with sign extension
            end
            `OP_BEQ: begin
                // B-type: (BLT has the same format)
                r_imm = {{19{i_inst[31]}}, i_inst[31], i_inst[7], i_inst[30:25], i_inst[11:8], 1'b0}; // r_imm[12], r_imm[10:5], r_imm[4:1], r_imm[11]
            end
            default: begin
                // invalid instruction
                r_imm = 0;
            end
        endcase
    end


endmodule