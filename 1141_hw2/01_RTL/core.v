module core #( // DO NOT MODIFY INTERFACE!!!
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
) ( 
    input i_clk,
    input i_rst_n,

    // Testbench IOs
    output [2:0] o_status, 
    output       o_status_valid,

    // Memory IOs
    output [ADDR_WIDTH-1:0] o_addr,
    output [DATA_WIDTH-1:0] o_wdata,
    output                  o_we,
    input  [DATA_WIDTH-1:0] i_rdata
);


    localparam S_IDLE = 0;
    localparam S_FETCH_INST = 1;
    localparam S_DECODE_INST = 2;
    localparam S_OPERATION = 3;
    localparam S_WBACK = 4;


// ---------------------------------------------------------------------------
// Wires and Registers
// ---------------------------------------------------------------------------
// ---- Add your own wires and registers here if needed ---- //
    reg [2:0] state_next,state_r;
    reg [DATA_WIDTH-1:0] pc_r, pc_next;
    reg [1:0] fetech_count_r, fetech_count_next;
    reg [1:0] operation_count_r, operation_count_next;
    reg [ADDR_WIDTH-1:0] o_addr_r, o_addr_next;
    assign o_addr = o_addr_r;
    reg [DATA_WIDTH-1:0] o_wdata_r, o_wdata_next;
    assign o_wdata = o_wdata_r;
    reg [DATA_WIDTH-1:0] i_rdata_r, i_rdata_next;
    reg o_we_r, o_we_next;
    assign o_we = o_we_r;
    wire [6:0] opcode;
    wire [2:0] func3;
    wire [6:0] func7;
    wire [DATA_WIDTH-1:0] imm;
    wire [4:0] rd_addr;
    wire [4:0] rs1_addr;
    wire [4:0] rs2_addr;

    assign opcode = i_rdata_r[6:0];
    assign func3 = i_rdata_r[14:12];
    assign func7 = i_rdata_r[31:25];
    assign rd_addr = i_rdata_r[11:7];
    assign rs1_addr = i_rdata_r[19:15];
    assign rs2_addr = i_rdata_r[24:20];

    reg [DATA_WIDTH-1:0] imm_r, imm_w;
    assign imm = imm_r;

    wire [2:0] status_result, status_result_next;
    wire alu_zero, alu_less, alu_invalid;
    
    reg signed[DATA_WIDTH-1:0] pc_next, pc_r;
    reg status_valid_r, status_valid_next;
    
    assign o_status_valid = status_valid_r;
    assign status_valid_next = (state_next==S_WBACK) ? 1'b1 : 1'b0;


    status_imm #(
        .DATA_WIDTH    (DATA_WIDTH)
    ) core_status_imm (
        .i_inst        (i_rdata),
        .o_imm         (imm),

        .i_alu_result     (alu_result),
        .i_alu_invalid    (alu_invalid),
        .i_opcode         (opcode),
        .o_status         (status_result)
    );
    
    wire ctrl_branch, 
         ctrl_mem_read, 
         ctrl_mem_to_reg,

         ctrl_mem_write, 
         ctrl_alu_src, 
         ctrl_reg_write,

         ctrl_rd_typ, 
         ctrl_rs1_typ,
         ctrl_rs2_typ; 
    wire [3:0] ctrl_alu_op;
    

    control core_control (
        .i_opcode        (opcode),
        .i_funct3        (func3),
        .i_funct7        (func7),
        .o_branch        (ctrl_branch),
        .o_mem_read      (ctrl_mem_read),
        .o_mem_to_reg    (ctrl_mem_to_reg),
        .o_alu_op      (ctrl_alu_op),
        .o_mem_write     (ctrl_mem_write),
        .o_alu_src       (ctrl_alu_src),
        .o_reg_write     (ctrl_reg_write),
        .o_rd_typ       (ctrl_rd_typ),
        .o_rs1_typ      (ctrl_rs1_typ),
        .o_rs2_typ      (ctrl_rs2_typ)
    );
//  assign opcode = i_rdata_r[6:0];
//     assign func3 = i_rdata_r[14:12];
//     assign func7 = i_rdata_r[31:25];
//     assign rd_addr = i_rdata_r[11:7];
//     assign rs1_addr = i_rdata_r[19:15];
//     assign rs2_addr = i_rdata_r[24:20];
   
  
    wire [DATA_WIDTH-1:0] reg_write_data;
    
    wire i_we_ctrl;
    assign i_we_ctrl = (state_r==S_WBACK) ? ctrl_reg_write : 1'b0;

    register #(
        .DATA_WIDTH (DATA_WIDTH),
        .ADDR_WIDTH (5),
        .FRAC_REG_NUM(32),
        .INT_REG_NUM(32)
    ) core_register (
        .i_clk       (i_clk),
        .i_rst_n     (i_rst_n),
        .i_we        (i_we_ctrl),
        .i_w_addr    (rd_addr),
        .i_w_data    (reg_write_data),
        .i_w_data_typ(ctrl_rd_typ),

        .i_rs1_addr  (rs1_addr),
        .i_rs2_addr  (rs2_addr),

        .o_rs1_data  (rs1_data),
        .o_rs2_data  (rs2_data),

        .i_rs1_dtyp  (ctrl_rs1_typ),
        .i_rs2_dtyp  (ctrl_rs2_typ)
    );
    
    
    
    // wire [DATA_WIDTH-1:0] rs1_data_alu, rs2_data_alu;
    // assign rs1_data_alu = rs1_data;
    // assign rs2_data_alu = (ctrl_alu_src) ? imm : rs2_data;
//  wire alu_zero, alu_less, alu_invalid;
    reg [DATA_WIDTH-1:0] rs1_data_alu, rs2_data_alu;
    always@(*) begin
        rs1_data_alu = rs1_data;
        if (ctrl_alu_src) begin
            rs2_data_alu = imm;
        end
        else begin
            rs2_data_alu = rs2_data;
        end
        if(opcode==`OP_JALR) begin
            rs2_data_alu = 4;
            rs1_data_alu = pc_r;//$rd = $pc + 4;
        end
        if(opcode==`OP_AUIPC) begin
            rs1_data_alu = pc_r;
            rs2_data_alu = (imm<<12);//$rd = $pc + (im << 12)
        end

    end
    wire [DATA_WIDTH-1:0] alu_result;
    alu #(
        .DATA_WIDTH (DATA_WIDTH)
    ) core_alu (
        .o_zero_flag (alu_zero),
        .o_less_flag (alu_less),
        .o_invalid_flag(alu_invalid)
        .i_alu_ctrl   (ctrl_alu_op),
        .i_alu_rs1   (rs1_data_alu),
        .i_alu_rs2   (rs2_data_alu),
        .o_alu_out   (alu_result),
        
    );
    assign reg_write_data = (ctrl_mem_to_reg) ? i_rdata : alu_result;

    always @(*) begin
        state_next = state_r;
        pc_next = pc_r;
        fetech_count_next = fetech_count_r;
        o_addr_next = o_addr_r;
        o_wdata_next = o_wdata_r;
        i_rdata_next = i_rdata_r;
        o_we_next = o_we_r;
        operation_count_next = operation_count_r;
        case(state_r)
            S_IDLE: begin
                fetech_count_next = 2'd0;
                operation_count_next = 2'd0;
                state_next = S_FETCH_INST;
                pc_next = 0;
            end
            S_FETCH_INST: begin
                if (fetech_count_r == 2'd0) begin
                    fetech_count_next = 2'd1;
                    operation_count_next = 2'd0;
                    state_next = S_FETCH_INST;
                end
                else if (fetech_count_r == 2'd1) begin
                    fetech_count_next = 2'd0;
                    operation_count_next = 2'd0;
                    state_next = S_DECODE_INST;
                    i_rdata_next = i_rdata;
                end
                
            end
            S_DECODE_INST: begin
                state_next = S_OPERATION;
                operation_count_next = 2'd0;   
            end
            S_OPERATION: begin
                 if (opcode_r == `OP_LW || opcode_r == `OP_FLW) begin
                    if (operation_count_r == 1) begin
                        state_next = S_WBACK;
                        fetech_count_next = 2'd0;
                        operation_count_next = 2'd0;
                    end 
                    else begin
                        state_next = S_OPERATION;
                        operation_count_next = operation_count_r + 1;
                        fetech_count_next = 2'd0;
                    end
                end else begin
                    state_next = S_WBACK;
                    operation_count_next = 2'd0;
                    fetech_count_next = 2'd0;
                end

            end

            S_WBACK: begin
                state_next = S_FETCH_INST;
                operation_count_next = 2'd0;
                fetech_count_next = 2'd0;
            end

            default: begin
                state_next = S_IDLE;
                operation_count_next = 2'd0;
                fetech_count_next = 2'd0;
            end

        endcase
    end



    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            state_r <= S_IDLE;
            pc_r <= 0;
            status <= status_result;
            fetech_count_r <= 2'd0;
            operation_count_r <= 2'd0;
            o_addr_r <= 0;
            o_wdata_r <= 0;
            i_rdata_r <= 0;
            o_we_r <= 1'b0;
            status_valid_r <= 1'b0;
        end
        else begin
            state_r <= state_next;
            pc_r <= pc_next;
            fetech_count_r <= fetech_count_next;
            o_addr_r <= o_addr_next;
            o_wdata_r <= o_wdata_next;
            i_rdata_r <= i_rdata_next;
            o_we_r <= o_we_next;
            status_next <= status_result;
            operation_count_r <= operation_count_next;
            fetech_count_r<=fetech_count_next;
            status_valid_r <= status_valid_next;

        end
    end
// ---------------------------------------------------------------------------
// Continuous Assignment
// ---------------------------------------------------------------------------
// ---- Add your own wire data assignments here if needed ---- //

// ---------------------------------------------------------------------------
// Combinational Blocks
// ---------------------------------------------------------------------------
// ---- Write your conbinational block design here ---- //

// ---------------------------------------------------------------------------
// Sequential Block
// ---------------------------------------------------------------------------
// ---- Write your sequential block design here ---- //

endmodule