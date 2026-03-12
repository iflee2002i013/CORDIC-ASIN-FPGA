module cordic_arcsin
    import cordic_const_pkg::*;
(
    input logic clk,
    input logic rst_n,
    // --输入数据和控制--
    input logic [SINA_W-1:0] sina,
    input logic trig,
    // --输出数据和控制--
    output logic signed [ARCSIN_SIGN_W-1:0] arcsina,
    output logic vld
);

logic [ROM_ADDR_WIDTH-1:0] angle_rom_addr;
logic [ROM_DATA_WIDTH-1:0] angle_rom_data;

// 数据通路寄存器
logic [XY_W-1:0] x_q, x_d;
logic [XY_W-1:0] y_q, y_d;
logic [T_W-1:0]  t_q, t_d;
logic [Z_W-1:0]  z_q, z_d;

logic [3:0] itr_q, itr_d;
logic vld_q, lvd_d;
logic delta;


angle_rom u_angle_rom(
	.addr 	( angle_rom_addr  ),
	.data 	( angle_rom_data  )
);

always_ff @(posedge clk or negedge rst_n)begin
    if (!rst_n) begin
        x_q   <= '0;
        y_q   <= '0;
        z_q   <= '0;
        t_q   <= '0;
        itr_q <= '0;
        vld <= 1'b0;
    end else begin
        x_q <= x_d;
        y_q <= y_d;
        z_q <= z_d;
        t_q <= t_d;
        itr_q <= itr_d;
        vld_q <= vld_d;
    end
end


endmodule