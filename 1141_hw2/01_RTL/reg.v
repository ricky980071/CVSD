module reg#(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 5,
    parameter FRAC_REG_NUM=32,
    parameter INT_REG_NUM=32

)(
    input                   i_clk,
    input                   i_rst_n,
    input                   i_we,       // 写使能，高电平有效
`   input  [ADDR_WIDTH-1:0] i_w_addr,     // 写入reg地址
`   input  [DATA_WIDTH-1:0] i_w_data,     // 写入regdata
    input                   i_w_data_type,

    input  [ADDR_WIDTH-1:0] i_rs1_addr,     // 读出地址
    input  [ADDR_WIDTH-1:0] i_rs2_addr,     // 读出地址

    output [DATA_WIDTH-1:0] o_rs1_data,     // 读出地址
    output [DATA_WIDTH-1:0] o_rs2_data,     // 读出地址

    input  [DATA_WIDTH-1:0] i_rs1_dtyp,     // 读出地址
    input [DATA_WIDTH-1:0] i_rs2_dtyp,     // 读出地址

);
reg signed [DATA_WIDTH-1:0] int_reg_file [0:INT_REG_NUM-1];
reg [DATA_WIDTH-1:0] fract_reg_file [0:FRAC_REG_NUM-1];
reg [DATA_WIDTH-1:0] o_rs1_data, o_rs2_data;

integer i;
always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        for (i = 0; i < INT_REG_NUM; i = i + 1) begin
            int_reg_file[i] <= 32'b0;
        end
        for (i = 0; i < FRAC_REG_NUM; i = i + 1) begin
            fract_reg_file[i] <= 32'b0;
        end
    end
    else begin
        if (i_we) begin
            if (i_w_data_type==1'b0) begin // int
                int_reg_file[i_w_addr] <= i_w_data;
            end
            else begin // fract
                fract_reg_file[i_w_addr] <= i_w_data;
            end
        end
    end

end

endmodule