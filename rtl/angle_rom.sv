
module angle_rom
    import cordic_const_pkg::*;
(
    input logic [ROM_ADDR_WIDTH-1:0] addr,
    output logic [ROM_DATA_WIDTH-1:0] data
);
    always_comb begin
        unique case (addr)
            4'd0 : data = 10'd237;
            4'd1 : data = 10'd125;
            4'd2 : data = 10'd64;
            4'd3 : data = 10'd32;
            4'd4 : data = 10'd16;
            4'd5 : data = 10'd8;
            4'd6 : data = 10'd4;
            4'd7 : data = 10'd2;
            4'd8 : data = 10'd1;
            4'd9 : data = 10'd0;
            4'd10: data = 10'd0;
            default: data = '0; 
        endcase
    end
endmodule
