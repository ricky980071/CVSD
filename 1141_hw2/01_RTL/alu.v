`define INT_ADD 4'd0
`define INT_SUB 4'd1
`define INT_SLT 4'd2
`define INT_SRL 4'd3
`define FRACT_FSUB 4'd4
`define FRACT_FMUL 4'd5
`define FRACT_FCVTWS 4'd6
`define FRACT_FCLASS 4'd7
`define NOP 4'd8

module alu #(
    parameter DATA_WIDTH = 32
)(
    input  [DATA_WIDTH-1:0] i_alu_in1,      // 第一个操作数
    input  [DATA_WIDTH-1:0] i_alu_in2,      // 第二个操作数
    input  [3:0]            i_alu_ctrl,     // ALU 控制信号
    output [DATA_WIDTH-1:0] o_alu_out,  // ALU 输出
    output                  o_zero_flag,     // 零标志位
    output                  o_invalid_flag,
    output                  o_less_flag
);

// all combinational block
reg [DATA_WIDTH-1:0] alu_out, alu_out_temp;
reg invalid_flag;
assign o_alu_out = alu_out;
assign o_invalid_flag = invalid_flag;
assign o_less_flag = alu_out[DATA_WIDTH-1];
assign o_zero_flag = (alu_out == 0) ? 1'b1 : 1'b0;

always @(*) begin
    invalid_flag = 1'b0;
    case (i_alu_ctrl)
        `INT_ADD: begin
            
            if((alu_out!=i_alu_in1[DATA_WIDTH-1])&&(i_alu_in1[DATA_WIDTH-1]==i_alu_in2[DATA_WIDTH-1])) begin
                invalid_flag = 1'b1; // overflow
                alu_out = 32'b0;
            end
            else alu_out = $signed(i_alu_in1) + $signed(i_alu_in2);
        end
        `INT_SUB: begin
            if((alu_out!=i_alu_in1[DATA_WIDTH-1])&&(i_alu_in1[DATA_WIDTH-1]!=i_alu_in2[DATA_WIDTH-1])) begin
                invalid_flag = 1'b1; // overflow
                alu_out = 32'b0;
            end
            else alu_out = $signed(i_alu_in1) - $signed(i_alu_in2);
        end
        `INT_SLT: begin
            alu_out = (i_alu_in1 < i_alu_in2) ? 32'd1 : 32'd0;
        end
        `INT_SRL: begin
            alu_out = i_alu_in1 >> i_alu_in2[4:0];
        end
        `FRACT_FSUB: begin
            // alu_out_temp = $realtobits($bitstoreal(i_alu_in1) - $bitstoreal(i_alu_in2));
            // alu_out = alu_out_temp;
            // if ($bitstoreal(i_alu_in1) == $bitstoreal(i_alu_in2)) begin
            //     alu_out = 32'b0; // +0
            // end
            // if ($bitstoreal(i_alu_in1) == 32'h7f800000 && $bitstoreal(i_alu_in2) == 32'h7f800000) begin
            //     invalid_flag = 1'b1; // inf - inf = NaN
            // end
            // if ($bitstoreal(i_alu_in1) == 32'hff800000 && $bitstoreal(i_alu_in2) == 32'hff800000) begin
            //     invalid_flag = 1'b1; // -inf - (-inf) = NaN
            // end
            // if (($bitstoreal(i_alu_in1) == 32'h7f800000 && $bitstoreal(i_alu_in2) == 32'hff800000) ||
            //     ($bitstoreal(i_alu_in1) == 32'hff800000 && $bitstoreal(i_alu_in2) == 32'h7f800000)) begin
            //     alu_out = i_alu_in1; // inf - (-inf) = inf, -inf - inf = -inf
            // end
        end
        `FRACT_FMUL: begin
            // alu_out_temp = $realtobits($bitstoreal(i_alu_in1) * $bitstoreal(i_alu_in2));
            // alu_out = alu_out_temp;
            // if ($bitstoreal(i_alu_in1) == 32'h7f800000 && $bitstoreal(i_alu_in2) == 32'h7f800000) begin
            //     invalid_flag = 1'b1; // inf * inf = NaN
            // end
            // if ($bitstoreal(i_alu_in1) == 32'hff800000 && $bitstoreal(i_alu_in2) == 32'hff800000) begin
            //     invalid_flag = 1'b1; // -inf * -inf = NaN
            // end
            // if (($bitstoreal(i_alu_in1) == 32'h7f800000 && $bitstoreal(i_alu_in2) == 32'hff800000) ||
            //     ($bitstoreal(i_alu_in1) == 32'hff800000 && $bitstoreal(i_alu_in2) == 32'h7f800000)) begin
            //     alu_out = 32'h7fc00000; // inf * -inf = -inf, -inf * inf = inf
            // end
        end
        `FRACT_FCVTWS: begin
            invalid_flag = 1'b0;
            alu_out=0;
        end
        `FRACT_FCLASS: begin
            invalid_flag = 1'b0;
            alu_out=0;
        end
        `FRACT_FMUL: begin
            invalid_flag = 1'b0;
            alu_out=0;
        end
        `NOP: begin
            invalid_flag = 1'b0;
            alu_out=0;
        end
        default: begin
                invalid = 1; // invalid alu_ctrl
                result = 0;
            end
        
        
    endcase
end
endmodule