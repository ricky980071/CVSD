module register#(
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
    input                   i_w_data_typ,

    input  [ADDR_WIDTH-1:0] i_rs1_addr,     // 读出地址
    input  [ADDR_WIDTH-1:0] i_rs2_addr,     // 读出地址

    output [DATA_WIDTH-1:0] o_rs1_data,     // 读出地址
    output [DATA_WIDTH-1:0] o_rs2_data,     // 读出地址

    input  [DATA_WIDTH-1:0] i_rs1_dtyp,     // 读出地址
    input [DATA_WIDTH-1:0] i_rs2_dtyp,     // 读出地址

);
reg signed [DATA_WIDTH-1:0] int_reg_file [0:INT_REG_NUM-1];
reg [DATA_WIDTH-1:0] fract_reg_file [0:FRAC_REG_NUM-1];

assign o_rs1_data = (i_rs1_dtyp==1'b0) ? int_reg_file[i_rs1_addr] : fract_reg_file[i_rs1_addr];
assign o_rs2_data = (i_rs2_dtyp==1'b0) ? int_reg_file[i_rs2_addr] : fract_reg_file[i_rs2_addr];

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
            if (i_w_data_typ==1'b0) begin // int
                int_reg_file[i_w_addr] <= i_w_data;
            end
            else begin // fract
                fract_reg_file[i_w_addr] <= i_w_data;
            end
        end
    end

end

endmodule