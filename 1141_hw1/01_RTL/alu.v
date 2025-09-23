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
reg o_busy_r,
    o_out_valid_r,
    o_busy_next,
    o_out_valid_next;
reg [DATA_W-1:0] o_data_r,o_data_next;

assign o_busy = o_busy_r;
assign o_out_valid = o_out_valid_r;
assign o_data = o_data_r;
//state machine logic(o_data logic control by calculation) the rest flag logic control by state machine
//stae using mealy machine
always@(*) begin
    state_next = state_r;
    o_busy_next = o_busy_r;
    o_out_valid_next = o_out_valid_r;
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
            o_busy_next = 1;
            o_out_valid_next = 1;
        end
        S_OUTPUT:begin
            state_next = S_LOAD;
            o_busy_next = 0;
            o_out_valid_next = 0;
        end
    endcase
end
reg signed [DATA_W-1:0] data_a_r,data_b_r,data_a_next,data_b_next;
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


reg signed [DATA_W:0] data_a_ext,data_b_ext; //one more bit for overflow
reg signed [DATA_W:0] temp_sum;

//MAC

localparam MAC_INT_W = 16;
localparam MAC_FRAC_W = 20;
localparam DATA_MAC_W = MAC_INT_W + MAC_FRAC_W;
reg signed [DATA_MAC_W-1:0] acc_mac_next,
                            acc_mac_r,
                            mul_mac_temp;
                            

//calculation logic
always@(*) begin
    o_data_next=o_data_r;
    data_a_ext=$signed({data_a_r[DATA_W-1],data_a_r[DATA_W-1:0]});
    data_b_ext=$signed({data_b_r[DATA_W-1],data_b_r[DATA_W-1:0]});
    acc_mac_next=acc_mac_r;
   
    temp_sum=0;
    mul_mac_temp=0;
    if(state_r==S_PROCESS)begin
        case(inst_r)
            4'b0000: begin
                temp_sum = data_a_ext + data_b_ext;
                if($signed(temp_sum)>$signed(16'h7fff))begin
                    o_data_next = 16'h7fff;
                end
                else if ($signed(temp_sum)<$signed(16'h8000))begin
                    o_data_next = 16'h8000;
                end
                else o_data_next = data_a_r + data_b_r; // add
            end

            4'b0001: begin
                temp_sum = data_a_ext - data_b_ext;
                if($signed(temp_sum)>$signed(16'h7fff))begin
                    o_data_next = 16'h7fff;
                end
                else if ($signed(temp_sum)<$signed(16'h8000))begin
                    o_data_next = 16'h8000;
                end
                else o_data_next = data_a_r - data_b_r; // sub
            end
            // 4'b0010: begin//MAC
            //     mul_mac_temp = $signed(data_a_r) * $signed(data_b_r); //mult 6Q10*6Q10=12Q20
            //     acc_mac_next = mul_mac_temp+acc_mac_r;
            //     if($signed(acc_mac_next)>$signed(16'h7fff))begin//saturation
            //         o_data_next = 16'h7fff;
            //     end
            //     else if ($signed(acc_mac_next)<$signed(16'h8000))begin//saturation
            //         o_data_next = 16'h8000;
            //     end
            //     else o_data_next = $signed(acc_mac_next >>>(MAC_FRAC_W-FRAC_W))+acc_mac_next[FRAC_W-1];// sub   16Q20->6Q10

            // end    
            4'b0010: begin//MAC
            mul_mac_temp = $signed(data_a_r) * $signed(data_b_r); //mult 6Q10*6Q10=12Q20
            acc_mac_next = mul_mac_temp+acc_mac_r;
            
            // 詳細顯示MAC運算過程
            $display("=== MAC Operation at time %0t ===", $time);
            $display("Input data_a_r = %016b (%0d decimal)", data_a_r, $signed(data_a_r));
            $display("Input data_b_r = %016b (%0d decimal)", data_b_r, $signed(data_b_r));
            $display("Multiplication result = %036b (%0d decimal)", mul_mac_temp, $signed(mul_mac_temp));
            $display("Previous accumulator  = %036b (%0d decimal)", acc_mac_r, $signed(acc_mac_r));
            $display("New accumulator      = %036b (%0d decimal)", acc_mac_next, $signed(acc_mac_next));
            
            if($signed(acc_mac_next)>$signed(16'h7fff))begin//saturation
                o_data_next = 16'h7fff;
                $display("POSITIVE SATURATION: acc_mac_next > 0x7fff");
                $display("Output saturated to  = %016b (0x%04h, %0d decimal)", o_data_next, o_data_next, $signed(o_data_next));
            end
            else if ($signed(acc_mac_next)<$signed(16'h8000))begin//saturation
                o_data_next = 16'h8000;
                $display("NEGATIVE SATURATION: acc_mac_next < 0x8000");
                $display("Output saturated to  = %016b (0x%04h, %0d decimal)", o_data_next, o_data_next, $signed(o_data_next));
            end
            else begin
                o_data_next = $signed(acc_mac_next >>>(MAC_FRAC_W-FRAC_W))+acc_mac_next[FRAC_W-1];// sub   16Q20->6Q10
                $display("NO SATURATION - Normal scaling:");
                $display("Right shift amount   = %0d bits", (MAC_FRAC_W-FRAC_W));
                $display("Shifted result       = %036b (%0d decimal)", $signed(acc_mac_next >>>(MAC_FRAC_W-FRAC_W)), $signed(acc_mac_next >>>(MAC_FRAC_W-FRAC_W)));
                $display("Rounding bit         = %01b", acc_mac_next[FRAC_W-1]);
                $display("Final output         = %016b (0x%04h, %0d decimal)", o_data_next, o_data_next, $signed(o_data_next));
            end
            $display("=====================================");
            end
        endcase
    end
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
       
        acc_mac_r<=0;
    end
    else begin
        o_busy_r<=o_busy_next;
        o_out_valid_r<=o_out_valid_next;
        o_data_r<=o_data_next;
        state_r<=state_next;
        data_a_r<=data_a_next;
        data_b_r<=data_b_next;
        inst_r<=inst_next;
        acc_mac_r<=acc_mac_next;
    end
end
endmodule
