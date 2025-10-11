`define INT_ADD 4'd0
`define INT_SUB 4'd1
`define INT_SLT 4'd2
`define INT_SRL 4'd3
`define FRACT_FSUB 4'd4
`define FRACT_FMUL 4'd5
`define FRACT_FCVTWS 4'd6
`define FRACT_FCLASS 4'd7
`define NOP 4'd8

module control (
    input  [6:0] i_opcode,       // opcode 字段
    input  [2:0] i_funct3,       // funct3 字段
    input  [6:0] i_funct7,       // funct7 字段
    
    output       o_branch,       // 分支指令标志
    output       o_mem_read,
    output       o_mem_to_reg,   // 寄存器堆写数据选择，1：数据存储器读出数据，0：ALU 结果
    output [3:0] o_alu_op,     // ALU 控制信号
    output       o_mem_write,       // 数据存储器写使能
    output       o_alu_src,      // ALU 第二操作数选择，1：立即数，0：寄存器堆读出数据
    output       o_reg_write,       // 寄存器堆写使能
    output       o_rd_typ,      
    output       o_rs1_typ,     
    output       o_rs2_typ      
);
reg        branch;
reg        mem_read;
reg        mem_to_reg;
reg [3:0]  alu_op;
reg        mem_write;
reg        alu_src;
reg        reg_write;
reg        rd_typ;
reg        rs1_typ;
reg        rs2_typ;
assign o_branch     = branch;
assign o_mem_read   = mem_read;
assign o_mem_to_reg = mem_to_reg;
assign o_alu_op     = alu_op;
assign o_mem_write  = mem_write;
assign o_alu_src    = alu_src;
assign o_reg_write  = reg_write;
assign o_rd_typ     = rd_typ;
assign o_rs1_typ    = rs1_typ;
assign o_rs2_typ    = rs2_typ;

always @(*) begin
    
    case (i_opcode)
            `OP_SUB: begin
                case (i_funct3)
                    `FUNCT3_SUB: begin
                        branch = 0;
                        mem_read = 0;

                        mem_to_reg = 0;
                        mem_write = 0;
                        alu_src = 0;
                        reg_write = 1;
                        rd_typ = 0;
                        rs1_typ = 0;
                        rs2_typ = 0;
                        alu_op = `INT_SUB;
                    end
                    `FUNCT3_SLT: begin
                        branch = 0;
                        mem_read = 0;

                        mem_to_reg = 0;
                        mem_write = 0;
                        alu_src = 0;
                        reg_write = 1;
                        rd_typ = 0;
                        rs1_typ = 0;
                        rs2_typ = 0;
                        alu_op = `INT_SLT;
                    end
                    `FUNCT3_SRL: begin
                        branch = 0;
                        mem_read = 0;
                        mem_to_reg = 0;
                        mem_write = 0;
                        alu_src = 0;

                        reg_write = 1;
                        rd_typ = 0;
                        rs1_typ = 0;
                        rs2_typ = 0;
                        alu_op = `INT_SRL;
                    end
                endcase
            end
            `OP_ADDI: begin
                branch = 0;
                mem_read = 0;
                mem_to_reg = 0;
                mem_write = 0;
                alu_src = 1;
                reg_write = 1;
                rd_typ = 0;
                rs1_typ = 0;
                rs2_typ = 0;
                alu_op = `INT_ADD;
            end
          
            `OP_SW: begin
                branch = 0;
                mem_read = 0;
                mem_to_reg = 0;
                mem_write = 1;
                alu_src = 1;

                reg_write = 0;
                rd_typ = 0;
                rs1_typ = 0;
                rs2_typ = 0;
                alu_op = `INT_ADD;
              `OP_LW: begin
                branch = 0;
                mem_read = 1;
                mem_to_reg = 1;
                mem_write = 0;

                alu_src = 1;
                reg_write = 1;


                rd_typ = 0;
                rs1_typ = 0;
                rs2_typ = 0;
                alu_op = `INT_ADD;
            end    
            end
            `OP_BEQ: begin
                case (i_funct3)
                    `FUNCT3_BLT: begin
                        branch = 1;
                        mem_read = 0;
                        mem_to_reg = 0;
                        mem_write = 0;
                        alu_src = 0;
                        reg_write = 0;
                        rd_typ = 0;
                        rs1_typ = 0;
                        rs2_typ = 0;
                        alu_op = `INT_SUB;
                    end
                    `FUNCT3_BEQ: begin
                        branch = 1;
                        mem_read = 0;
                        mem_to_reg = 0;
                        mem_write = 0;
                        alu_src = 0;
                        reg_write = 0;
                        rd_typ = 0;
                        rs1_typ = 0;
                        rs2_typ = 0;
                        alu_op = `INT_SUB;
                    end
                    
                endcase
            end
           
            `OP_AUIPC: begin
                branch = 0;
                mem_read = 0;
                mem_to_reg = 0;
                mem_write = 0;
                alu_src = 1;
                reg_write = 1;
                rd_typ = 0;
                rs1_typ = 0;
                rs2_typ = 0;
                alu_op = `INT_ADD;
            end
             `OP_JALR: begin
                branch = 1;
                mem_read = 0;
                mem_to_reg = 0;
                mem_write = 0;
                alu_src = 1;
                reg_write = 1;
                rd_typ = 0;
                rs1_typ = 0;
                rs2_typ = 0;
                alu_op = `INT_ADD;
            end
            `OP_FSUB: begin
                case (i_funct7)
                    `FUNCT7_FSUB: begin
                        branch = 0;
                        mem_read = 0;
                        mem_to_reg = 0;
                        mem_write = 0;
                        alu_src = 0;
                        reg_write = 1;
                        rd_typ = 1;
                        rs1_typ = 1;
                        rs2_typ = 1;
                        alu_op = `FRACT_FSUB;
                    end
                    `FUNCT7_FMUL: begin
                        branch = 0;
                        mem_read = 0;
                        mem_to_reg = 0;
                        mem_write = 0;
                        alu_src = 0;
                        reg_write = 1;
                        rd_typ = 1;
                        rs1_typ = 1;
                        rs2_typ = 1;
                        alu_op = `FRACT_FMUL;
                    end
                    `FUNCT7_FCVTWS: begin
                        branch = 0;
                        mem_read = 0;
                        mem_to_reg = 0;
                        mem_write = 0;
                        alu_src = 0;
                        reg_write = 1;
                        rd_typ = 0;
                        rs1_typ = 1;
                        rs2_typ = 0;
                        alu_op = `FRACT_FCVTWS;
                    end
                    `FUNCT7_FCLASS: begin

                        branch = 0;
                        mem_read = 0;
                        mem_to_reg = 0;
                        mem_write = 0;
                        alu_src = 0;
                        reg_write = 1;
                        rd_typ = 0;
                        rs1_typ = 1;
                        rs2_typ = 0;
                        alu_op = `FRACT_FCLASS;
                    end
                endcase
            end
            `OP_FLW: begin

                branch = 0;
                mem_read = 1;
                mem_to_reg = 1;
                mem_write = 0;
                alu_src = 1;
                reg_write = 1;
                rd_typ = 1;
                rs1_typ = 0;
                rs2_typ = 0;
                alu_op = `INT_ADD;
            end
            `OP_FSW: begin

                branch = 0;
                mem_read = 0;
                mem_to_reg = 0;
                mem_write = 1;
                alu_src = 1;
                reg_write = 0;
                rd_typ = 0;
                rs1_typ = 0;
                rs2_typ = 1;
                alu_op = `INT_ADD;
            end
            `OP_EOF: begin
                branch = 0;
                mem_read = 0;
                mem_to_reg = 0;
                mem_write = 0;
                alu_src = 0;
                reg_write = 0;
                rd_typ = 0;
                rs1_typ = 0;
                rs2_typ = 0;
                alu_op = `NOP;
            end
            default: begin
                // if no commend or other situation
                branch = 0;
                mem_read = 0;
                mem_to_reg = 0;
                mem_write = 0;
                alu_src = 0;
                reg_write = 0;
                rd_typ = 0;
                rs1_typ = 0;
                rs2_typ = 0;
                alu_op = `NOP;
            end
        endcase
    end
endmodule