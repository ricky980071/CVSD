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
// genvar i; for outside always block

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
    integer i;
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
                if(i_inst==4'b1001) begin
                    if(cnt_r==4'd7)begin
                        state_next = S_PROCESS;
                        o_busy_next = 1;
                        o_out_valid_next = 0
                    end
                    else begin
                        state_next = S_LOAD;
                        o_busy_next = 0;
                        o_out_valid_next = 0;
                    end

                end
                else begin
                    state_next = S_PROCESS;
                    o_busy_next = 1;
                    o_out_valid_next = 0;
                end
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
            if(cnt_r>4'd0) begin
                    // if(cnt_r==4'd0)begin
                    //     state_next = S_LOAD;
                    //     o_busy_next = 0;
                    //     o_out_valid_next = 0
                    // end
                    // else begin
                        state_next = S_OUTPUT;
                        o_busy_next = 1;
                        o_out_valid_next = 1;
                        
                    // end

            end
            else begin
            state_next = S_LOAD;
            o_busy_next = 0;
            o_out_valid_next = 0;
            end
        end
    endcase
end
reg signed [DATA_W-1:0] data_a_r,data_b_r,data_a_next,data_b_next;
reg [INST_W-1:0] inst_r,inst_next;
//matrix ouput
always@(*) begin
    if(state_r==S_OUTPUT)begin
        o_data_next=matrix_r[cnt_r-1];
    end
    
end


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
        if(i_inst=4'b1001) begin
            
            matrix_next[cnt_r]=i_data_a;
        end
        else begin
            for(i=0;i<8;i=i+1) begin
            matrix_next[i]=matrix_r[i];
            end
        end
    end
    
end
reg [3:0] cnt_r,cnt_next;
//cnt logic
always@(*) begin
    if(state_r == S_LOAD&&inst_r==4'b1001) begin
        cnt_next=cnt_r+1;
    end
    else if(state_r == S_PROCESS) begin
        cnt_next=cnt_r-1;
    end
    else if(state_r==S_OUT)begin
        cnt_next=cnt_r-1;
    end
    else cnt_next=0;
end



reg signed [DATA_W:0] data_a_ext,data_b_ext; //one more bit for overflow
reg signed [DATA_W:0] temp_sum;

//MAC

localparam MAC_INT_W = 16;
localparam MAC_FRAC_W = 20;
localparam DATA_MAC_W = MAC_INT_W + MAC_FRAC_W;
reg signed [DATA_MAC_W-1:0] acc_mac_next,
                            acc_mac_r,
                            mul_mac_temp,
                            temp_gray,
                            temp_CPOP;
reg signed [DATA_W+FRAC_W*5-1:0] temp_tylr; //talor
localparam signed R_6 = 16'b0000000010101011; 
localparam signed R_120 = 16'b0000000000001001; 
reg CLZ_ctrl;
reg [4:0] CLZ_count;
reg [DATA_W-1:0] matched_seq;
reg [DATA_W-1:0] matrix_next [0:7];
reg [DATA_W-1:0] matrix_temp [0:7];
reg [DATA_W-1:0] matrix_r [0:7];
//calculation logic
always@(*) begin
    integer i,j;
    o_data_next=o_data_r;
    data_a_ext=$signed({data_a_r[DATA_W-1],data_a_r[DATA_W-1:0]});
    data_b_ext=$signed({data_b_r[DATA_W-1],data_b_r[DATA_W-1:0]});
    acc_mac_next=acc_mac_r;
    
    temp_sum=0;
    mul_mac_temp=0;
    temp_tylr=0;//talor
    temp_gray=0;
    CLZ_count=0;
    CLZ_ctrl=0;
    matched_seq=0;
    // temp_LRCW=0;
    temp_CPOP=0;
    for(i=0;i<8;i=i+1) begin
            matrix_temp[i]=0;
    end
    if(state_r ==S_PROCESS)begin
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
             
            4'b0010: begin//MAC
                mul_mac_temp = $signed(data_a_r) * $signed(data_b_r); //mult 6Q10*6Q10=12Q20
                acc_mac_next = mul_mac_temp+acc_mac_r;
                if($signed(acc_mac_next)>$signed((32'h7fff_ffff)))begin//saturation
                    o_data_next = 16'h7fff;
                    acc_mac_next = 32'h7fff_ffff;
                end
                else if ($signed(acc_mac_next)<$signed(32'h8000_0000))begin//saturation
                    o_data_next = 16'h8000;
                    acc_mac_next = 32'h8000_0000;
                end
                else begin
                    if($signed(acc_mac_next)>($signed({10'd0,16'h7fff,10'b0})))begin//saturation
                        o_data_next = 16'h7fff;
                    end
                    else if ($signed(acc_mac_next)<$signed({10'b1111111111,16'h8000,10'b0}))begin//saturation
                        o_data_next = 16'h8000;
                    end         
                    o_data_next = $signed(acc_mac_next >>>(MAC_FRAC_W-FRAC_W))+acc_mac_next[FRAC_W-1];// sub   16Q20->6Q10
                end
            end
            4'b0011: begin // Taylor 
                    temp_tylr = (data_a_r <<< (FRAC_W*5)) - ((data_a_r * data_a_r * data_a_r * R_6) <<< (FRAC_W*2)) + (data_a_r * data_a_r * data_a_r * data_a_r * data_a_r * R_120);
                    o_data_next = (temp_tylr >>> (FRAC_W*5)) + temp_tylr[(FRAC_W*5) - 1]; 
                end
            4'b0100: begin 
                   for(i=0;i<DATA_W;i=i+1) begin
                    if(i==DATA_W-1) temp_gray[DATA_W-1]=data_a_r[DATA_W-1];
                    else temp_gray[i]=data_a_r[i+1]^data_a_r[i];
                end
                o_data_next = temp_gray;
            end
            4'b0101:begin
                for(i=0;i<DATA_W;i=i+1) begin
                    if(data_a_r[i]) temp_CPOP = temp_CPOP + 1;
                end
                o_data_next = (data_b_r<<<temp_CPOP|(((~data_b_r)>>(DATA_W-temp_CPOP))));//shift left and right
            end
            4'b0110: begin
                o_data_next= (data_a_r >> data_b_r)|data_a_r<<(DATA_W-data_b_r); // shift left
            end
            4'b0111: begin
                for (i=DATA_W-1;i>=0;i=i-1) begin
                    if((!data_a_r[i])&&(!CLZ_ctrl)) begin
                        CLZ_count=CLZ_count+1;
                    end
                    else begin
                        CLZ_ctrl=1;
                    end
                end
                o_data_next = CLZ_count;
            end
            4'b1000: begin
                for (i=0;i<DATA_W-3;i=i+1) begin
                    if(((data_a_r[i+3:i]^~data_b_r[DATA_W-1-i:DATA_W-4-i]))==0)begin
                        matched_seq[i] = 1'b1;
                    end
                    else matched_seq[i] = 1'b0;
                end
                o_data_next = matched_seq;
            end
                
            4'b1001: begin//matrix
                
                
                for(i=7;i>=0;i=i-1) begin
                    for(j=0;j<8;j=j+1) begin
                        matrix_temp[7-i][15-2*j:14-2*j]=matrix_r[j][2*i+1:2*i];
                    end
                end
                for(i=7;i>=0;i=i-1) begin
                    matrix_next[i]=matrix_temp[i];
                end
                o_data_next=matrix_next[cnt_r-1];
            end
        endcase
    end
end


always@(posedge i_clk or negedge i_rst_n) begin
    integer i;
    if(!i_rst_n) begin
        o_busy_r<=0;
        o_out_valid_r<=0;
        o_data_r<=0;
        state_r<=S_IDLE;
        data_a_r<=0;
        data_b_r<=0;
        inst_r<=0;
       
        acc_mac_r<=0;
        cnt_r<=0;
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
        cnt_r<=cnt_next;
        for(i=0;i<8;i=i+1) begin
            matrix_r[i]<=matrix_next[i];
        end
    end 
end
endmodule
