`timescale 1ns / 1ps
// =============================================================================
// Testbench : tb_cordic_asin
// DUT       : cordic_asin
//
// Applies a set of representative inputs over the valid input range [-1, 1]
// and verifies that each output is within ±8 LSBs of the ideal value.
// (8 LSBs at scale 8192 = 0.001 rad ≈ 0.057 degrees — well within FPGA spec.)
//
// Fixed-point: Q2.13 (scale = 8192)
// =============================================================================

module tb_cordic_asin;

    // -----------------------------------------------------------------------
    // Parameters
    // -----------------------------------------------------------------------
    localparam DATA_WIDTH = 16;
    localparam FRAC_BITS  = 13;
    localparam ITERATIONS = 14;
    localparam LATENCY    = ITERATIONS + 2; // pipeline depth
    localparam SCALE      = 8192;           // 2^FRAC_BITS
    localparam TOLERANCE  = 8;              // ±8 LSBs

    // -----------------------------------------------------------------------
    // DUT signals
    // -----------------------------------------------------------------------
    reg                   clk;
    reg                   rst_n;
    reg                   valid_in;
    reg  [DATA_WIDTH-1:0] x_in;
    wire                  valid_out;
    wire [DATA_WIDTH-1:0] angle_out;

    // -----------------------------------------------------------------------
    // DUT instantiation
    // -----------------------------------------------------------------------
    cordic_asin #(
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

    // -----------------------------------------------------------------------
    // Clock: 10 ns period
    // -----------------------------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    // -----------------------------------------------------------------------
    // Test vectors: {input_fp, expected_fp, description}
    //   input_fp   = sin_value * 8192  (16-bit signed)
    //   expected_fp = arcsin_rad * 8192 (16-bit signed)
    //
    //   arcsin( 0.000) =  0.000000 rad ->     0
    //   arcsin( 0.500) =  0.523599 rad ->  4292  (π/6)
    //   arcsin( 0.707) =  0.785398 rad ->  6434  (π/4)
    //   arcsin( 0.866) =  1.047198 rad ->  8581  (π/3)
    //   arcsin( 1.000) =  1.570796 rad -> 12868  (π/2)
    //   arcsin(-0.500) = -0.523599 rad -> -4292
    //   arcsin(-1.000) = -1.570796 rad -> -12868
    //   arcsin( 0.250) =  0.252680 rad ->  2071
    //   arcsin(-0.250) = -0.252680 rad -> -2071
    //   arcsin( 0.125) =  0.125333 rad ->  1027
    // -----------------------------------------------------------------------
    integer num_tests;
    integer num_pass;
    integer num_fail;

    reg signed [DATA_WIDTH-1:0] tv_in   [0:9];
    reg signed [DATA_WIDTH-1:0] tv_exp  [0:9];
    reg [63:0]                  tv_desc [0:9]; // truncated label

    initial begin
        tv_in[0] =  16'sd0;     tv_exp[0] =  16'sd0;
        tv_in[1] =  16'sd4096;  tv_exp[1] =  16'sd4292;  // 0.5
        tv_in[2] =  16'sd5793;  tv_exp[2] =  16'sd6434;  // 0.707
        tv_in[3] =  16'sd7094;  tv_exp[3] =  16'sd8581;  // 0.866
        tv_in[4] =  16'sd8192;  tv_exp[4] =  16'sd12868; // 1.0
        tv_in[5] = -16'sd4096;  tv_exp[5] = -16'sd4292;  // -0.5
        tv_in[6] = -16'sd8192;  tv_exp[6] = -16'sd12868; // -1.0
        tv_in[7] =  16'sd2048;  tv_exp[7] =  16'sd2071;  // 0.25
        tv_in[8] = -16'sd2048;  tv_exp[8] = -16'sd2071;  // -0.25
        tv_in[9] =  16'sd1024;  tv_exp[9] =  16'sd1027;  // 0.125
    end

    // -----------------------------------------------------------------------
    // Capture outputs as they arrive
    // -----------------------------------------------------------------------
    integer tv_idx_out;
    integer error;
    integer abs_error;

    initial begin
        num_tests  = 10;
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

    // -----------------------------------------------------------------------
    // Stimulus
    // -----------------------------------------------------------------------
    integer tv_idx_in;

    initial begin
        // Reset
        rst_n    = 1'b0;
        valid_in = 1'b0;
        x_in     = 16'sd0;
        repeat (4) @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);

        // Feed all test vectors one per cycle
        for (tv_idx_in = 0; tv_idx_in < num_tests; tv_idx_in = tv_idx_in + 1) begin
            @(posedge clk);
            valid_in <= 1'b1;
            x_in     <= tv_in[tv_idx_in];
        end

        // Keep valid low while pipeline drains
        @(posedge clk);
        valid_in <= 1'b0;

        // Wait for all results to emerge
        repeat (LATENCY + 4) @(posedge clk);

        // Report summary
        $display("----------------------------------------------------");
        $display("cordic_asin: %0d/%0d tests passed", num_pass, num_tests);
        if (num_fail == 0)
            $display("ALL TESTS PASSED");
        else
            $display("%0d TEST(S) FAILED", num_fail);
        $display("----------------------------------------------------");
        $finish;
    end

endmodule
