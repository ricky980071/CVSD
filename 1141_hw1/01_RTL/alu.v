module alu #(
    parameter INST_W = 4,
    parameter INT_W  = 6,
    parameter FRAC_W = 10,
    parameter DATA_W = INT_W + FRAC_W
)(
    input                      i_clk,
    input                      i_rst_n,

    input                      i_in_valid,
    output                     o_busy,
    input         [INST_W-1:0] i_inst,
    input  signed [DATA_W-1:0] i_data_a,
    input  signed [DATA_W-1:0] i_data_b,

    output                     o_out_valid,
    output        [DATA_W-1:0] o_data
);

localparam S_IDLE = 3'd1;
localparam S_LOAD  = 3'd2;

localparam S_PROCESS = 3'd3;
localparam S_OUTPUT = 3'd4;
reg [2:0]state_r,state_next;
reg o_busy_r,o_out_valid_r,o_busy_next,o_out_valid_next;
reg [DATA_W-1:0] o_data_r,o_data_next;

assign o_busy = o_busy_r;
assign o_out_valid = o_out_valid_r;
assign o_data = o_data_r;
//state machine logic(o_data logic control by calculation) the rest flag logic control by state machine
//stae using mealy machine
always@(*) begin
    state_next = state_r;
    case(state_r)
        S_IDLE:begin
            state_next = S_LOAD;
            o_busy_next = 0;
            o_out_valid_next = 0;
        end
        S_LOAD:begin
            if(i_in_valid) begin 
                state_next = S_PROCESS;
                o_busy_next = 1;
                o_out_valid_next = 0;
            end
            else begin                 
                state_next = S_LOAD;
                o_busy_next = 0;
                o_out_valid_next = 0;
            end
        end
        S_PROCESS:begin
            state_next = S_OUTPUT;
            o_busy_next = 0;
            o_out_valid_next = 1;
        end
        S_OUTPUT:begin
            state_next = S_LOAD;
            o_busy_next = 0;
            o_out_valid_next = 0;
        end
    endcase
end
reg [DATA_W-1:0] data_a_r,data_b_r,data_a_next,data_b_next;
reg [INST_W-1:0] inst_r,inst_next;
//input data logic
//without assign first if will be latch
always@(*) begin
    data_a_next=data_a_r;
    data_b_next=data_b_r;
    //avoid latch, without this, the if block below if not hold, 
    //the data_a_next will be unknown, so it needs to remenber the last value
    // to remenber the last value, it will be a latch
    //if you assign, it will be a mux
    inst_next=inst_r;
    if(state_r == S_LOAD && i_in_valid) begin
        data_a_next=i_data_a;
        data_b_next=i_data_b;
        inst_next=i_inst;
    end
    
end

//calculation logic
always@(*) begin
    o_data_next=o_data_r;
    case(inst_r)
        4'b0000: o_data_next = data_a_r + data_b_r; // add
        4'b0001: o_data_next = data_a_r - data_b_r; // sub
        default: o_data_next = {DATA_W{1'b0}};
    endcase
end


always@(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n) begin
        o_busy_r<=0;
        o_out_valid_r<=0;
        o_data_r<=0;
        state_r<=S_IDLE;
        data_a_r<=0;
        data_b_r<=0;
        inst_r<=0;
    end
    else begin
        o_busy_r<=o_busy_next;
        o_out_valid_r<=o_out_valid_next;
        o_data_r<=o_data_next;
        state_r<=state_next;
        data_a_r<=data_a_next;
        data_b_r<=data_b_next;
        inst_r<=inst_next;
    end
end
endmodule
