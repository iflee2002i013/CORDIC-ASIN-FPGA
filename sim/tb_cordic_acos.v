`timescale 1ns / 1ps
// =============================================================================
// Testbench : tb_cordic_acos
// DUT       : cordic_acos
//
// Applies representative inputs over [-1, 1] and verifies outputs are within
// ±8 LSBs of the ideal value.
//
// Fixed-point: Q2.13 (scale = 8192)
//   arccos( 1.000) =  0.000000 rad ->     0
//   arccos( 0.866) =  0.523599 rad ->  4292  (π/6)
//   arccos( 0.707) =  0.785398 rad ->  6434  (π/4)
//   arccos( 0.500) =  1.047198 rad ->  8581  (π/3)
//   arccos( 0.000) =  1.570796 rad -> 12868  (π/2)
//   arccos(-0.500) =  2.094395 rad -> 17155  (2π/3)
//   arccos(-1.000) =  3.141593 rad -> 25736  (π)
// =============================================================================

module tb_cordic_acos;

    localparam DATA_WIDTH = 16;
    localparam FRAC_BITS  = 13;
    localparam ITERATIONS = 14;
    localparam LATENCY    = ITERATIONS + 3;
    localparam TOLERANCE  = 8;

    reg                   clk;
    reg                   rst_n;
    reg                   valid_in;
    reg  [DATA_WIDTH-1:0] x_in;
    wire                  valid_out;
    wire [DATA_WIDTH-1:0] angle_out;

    cordic_acos #(
        .DATA_WIDTH (DATA_WIDTH),
        .FRAC_BITS  (FRAC_BITS),
        .ITERATIONS (ITERATIONS)
    ) dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .valid_in  (valid_in),
        .x_in      (x_in),
        .valid_out (valid_out),
        .angle_out (angle_out)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    integer num_tests;
    integer num_pass;
    integer num_fail;

    reg signed [DATA_WIDTH-1:0] tv_in  [0:6];
    reg signed [DATA_WIDTH-1:0] tv_exp [0:6];

    initial begin
        tv_in[0] =  16'sd8192;  tv_exp[0] =  16'sd0;     // cos=1.000
        tv_in[1] =  16'sd7094;  tv_exp[1] =  16'sd4292;  // cos=0.866
        tv_in[2] =  16'sd5793;  tv_exp[2] =  16'sd6434;  // cos=0.707
        tv_in[3] =  16'sd4096;  tv_exp[3] =  16'sd8581;  // cos=0.500
        tv_in[4] =  16'sd0;     tv_exp[4] =  16'sd12868; // cos=0.000
        tv_in[5] = -16'sd4096;  tv_exp[5] =  16'sd17155; // cos=-0.500
        tv_in[6] = -16'sd8192;  tv_exp[6] =  16'sd25736; // cos=-1.000
    end

    integer tv_idx_out;
    integer error;
    integer abs_error;

    initial begin
        num_tests  = 7;
        num_pass   = 0;
        num_fail   = 0;
        tv_idx_out = 0;
    end

    always @(posedge clk) begin
        if (valid_out && tv_idx_out < num_tests) begin
            error     = $signed(angle_out) - $signed(tv_exp[tv_idx_out]);
            abs_error = (error < 0) ? -error : error;

            if (abs_error <= TOLERANCE) begin
                $display("PASS  tv[%0d]: x_in=%0d  got=%0d  exp=%0d  err=%0d",
                         tv_idx_out, $signed(tv_in[tv_idx_out]),
                         $signed(angle_out), $signed(tv_exp[tv_idx_out]), error);
                num_pass = num_pass + 1;
            end else begin
                $display("FAIL  tv[%0d]: x_in=%0d  got=%0d  exp=%0d  err=%0d  (tol=%0d)",
                         tv_idx_out, $signed(tv_in[tv_idx_out]),
                         $signed(angle_out), $signed(tv_exp[tv_idx_out]),
                         error, TOLERANCE);
                num_fail = num_fail + 1;
            end
            tv_idx_out = tv_idx_out + 1;
        end
    end

    integer tv_idx_in;

    initial begin
        rst_n    = 1'b0;
        valid_in = 1'b0;
        x_in     = 16'sd0;
        repeat (4) @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);

        for (tv_idx_in = 0; tv_idx_in < num_tests; tv_idx_in = tv_idx_in + 1) begin
            @(posedge clk);
            valid_in <= 1'b1;
            x_in     <= tv_in[tv_idx_in];
        end

        @(posedge clk);
        valid_in <= 1'b0;

        repeat (LATENCY + 4) @(posedge clk);

        $display("----------------------------------------------------");
        $display("cordic_acos: %0d/%0d tests passed", num_pass, num_tests);
        if (num_fail == 0)
            $display("ALL TESTS PASSED");
        else
            $display("%0d TEST(S) FAILED", num_fail);
        $display("----------------------------------------------------");
        $finish;
    end

endmodule
