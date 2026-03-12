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
logic [XY_W-1:0] x_q, x_d, x_shift;
logic [XY_W-1:0] y_q, y_d, y_shift;
logic [T_W-1:0]  t_q, t_d, t_shift;
logic [Z_W-1:0]  z_q, z_d;

logic [3:0] itr_q, itr_d;
logic vld_q, vld_d;
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

always_comb begin
    // 默认保持上一拍的值 (防止锁存器 Latch 产生)
    x_d   = x_q;
    y_d   = y_q;
    z_d   = z_q;
    t_d   = t_q;
    itr_d = itr_q;
    vld_d = 1'b0; // vld 默认拉低，只有算完那一拍拉高

    x_shift = x_q >>> itr_q;
    y_shift = y_q >>> itr_q;
    t_shift = t_q >>> (2* itr_q + 1);

    delta = (y_q < t_q) ? 1'b1 : 1'b0;

    if(itr_q == 4'd0) begin
        if(trig)begin
            x_d = 13'd1546;
            y_d = 13'd1546;
            z_d = 10'd402;
            itr_d = 4'd1;
        end
    end
    else if (itr_q <= 4'd11) begin
        if(delta)begin
            x_d = x_q - y_shift;
            y_d = y_q + x_shift;
            z_d = z_q + angle_rom_data;
        end else begin
            x_d = x_q + y_shift;
            y_d = y_q - x_shift;
            z_d = z_q - angle_rom_data;
        end
        t_d = t_q + t_shift;
        itr_d = itr_q + 1'b1;
    end
    else begin
        vld_d = 1'b1;
        itr_d = 4'd0;
    end
end
assign arcsin = z_q;
endmodule