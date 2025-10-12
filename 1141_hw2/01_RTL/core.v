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

    wire [2:0] status_result;
    wire alu_zero, alu_less, alu_invalid;
    
    
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
    wire control_branch, control_mem_read, control_mem_to_reg;
    wire [3:0] control_alu_op;
    wire control_mem_write, control_alu_src, control_reg_write;
    wire control_rd_typ, control_rs1_typ, control_rs2_typ; // 0 for integer, 1 for float
    
    control core_control (
        .i_opcode        (opcode_r),
        .i_funct3        (funct3_r),
        .i_funct7        (funct7_r),
        .o_branch        (control_branch),
        .o_mem_read      (control_mem_read),
        .o_mem_to_reg    (control_mem_to_reg),
        .o_alu_op      (control_alu_op),
        .o_mem_write     (control_mem_write),
        .o_alu_src       (control_alu_src),
        .o_reg_write     (control_reg_write),
        .o_rd_typ       (control_rd_typ),
        .o_rs1_typ      (control_rs1_typ),
        .o_rs2_typ      (control_rs2_typ)
    );

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
        end
        else begin
            state_r <= state_next;
            pc_r <= pc_next;
            fetech_count_r <= fetech_count_next;
            o_addr_r <= o_addr_next;
            o_wdata_r <= o_wdata_next;
            i_rdata_r <= i_rdata_next;
            o_we_r <= o_we_next;
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