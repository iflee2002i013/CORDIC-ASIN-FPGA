
package cordic_const_pkg;
    localparam int ITR = 12; // 总迭代次数
    
    // --位宽确定--
    // arcsin 的位宽
    localparam int ARCSIN_SIGN_W = 11; // 总位宽(1符号位+2位整数）
    localparam int ARCSIN_SIGN_F = 9; // 小数位宽
    // sin 的位宽
    localparam int SINA_W = 13; // 总位宽（2位整数）
    localparam int SINA_F = 11;
    // XY的位宽
    localparam int XY_W = 14; // 总位宽（1位符号位+2位整数）
    localparam int XY_F = 11;
    // T的位宽
    localparam int T_W = 14; // 总位宽（1位符号位+2位整数）
    localparam int T_F = 11;
    // Z的位宽
    localparam int Z_W = 11;// 总位宽（1位符号位+1位整数）
    localparam int Z_F = 9;

    // --angle_rom 参数--
    localparam ROM_ADDR_WIDTH = $clog2(ITR); // 4
    localparam ROM_DATA_WIDTH = Z_W;

endpackage

