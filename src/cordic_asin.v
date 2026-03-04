`timescale 1ns / 1ps
// =============================================================================
// Module  : cordic_asin
// Purpose : Multiplier-less pipelined CORDIC for arcsine computation.
//           Based on the 2023 IEEE TCAS-II paper on optimised CORDIC for
//           inverse trigonometric functions.
//
// Algorithm (modified CORDIC rotation mode)
// ------------------------------------------
//   Initialise  : x = K_n, y = 0, z = 0
//   Decision    : d_i = +1 when target >= y_i, else -1
//                 (drives the running sine estimate y toward the target input)
//   Iteration   : x_{i+1} = x_i  - d_i * (y_i >> i)
//                 y_{i+1} = y_i  + d_i * (x_i >> i)
//                 z_{i+1} = z_i  + d_i * atan(2^{-i})
//   Result      : z_N ≈ arcsin(x_in)
//
//   Correctness proof sketch:
//     After N steps the CORDIC scale factor is K_n^{-1}, so
//       y_N = K_n^{-1} * K_n * sin(z_N) = sin(z_N)
//     Since we force y_N -> target we get z_N = arcsin(target). ✓
//
// Fixed-point format : Q2.13  (16-bit signed, scale = 2^13 = 8192)
//   x_in   ∈ [-1.0, +1.0]  → integer [-8192, +8192]
//   angle  ∈ [-π/2, +π/2]  → integer [-12868, +12868]
//
// Pipeline latency : ITERATIONS + 2 clock cycles
// Throughput       : 1 sample per clock cycle
// =============================================================================

module cordic_asin #(
    parameter DATA_WIDTH = 16,  // Bit width; 16-bit covers Q2.13 range
    parameter FRAC_BITS  = 13,  // Fractional bits; scale = 2^FRAC_BITS = 8192
    parameter ITERATIONS = 14   // CORDIC stages (14 gives < 0.001 rad error)
)(
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire                   valid_in,
    input  wire [DATA_WIDTH-1:0]  x_in,       // sin value  Q2.13 [-8192, 8192]
    output reg                    valid_out,
    output reg  [DATA_WIDTH-1:0]  angle_out   // arcsin(x_in) Q2.13 radians
);

    // -------------------------------------------------------------------------
    // CORDIC gain for ITERATIONS=14:  K_14 ≈ 0.607253
    //   K_14 * 2^FRAC_BITS = 0.607253 * 8192 ≈ 4975
    // -------------------------------------------------------------------------
    localparam signed [DATA_WIDTH-1:0] CORDIC_K = 16'sd4975;

    // -------------------------------------------------------------------------
    // arctan lookup table:  atan(2^{-i}) * 2^FRAC_BITS   (radians × 8192)
    // -------------------------------------------------------------------------
    reg signed [DATA_WIDTH-1:0] atan_lut [0:ITERATIONS-1];
    initial begin
        atan_lut[0]  = 16'sd6434;  // atan(2^0 ) = 0.785398 rad
        atan_lut[1]  = 16'sd3798;  // atan(2^-1) = 0.463648 rad
        atan_lut[2]  = 16'sd2008;  // atan(2^-2) = 0.244979 rad
        atan_lut[3]  = 16'sd1019;  // atan(2^-3) = 0.124355 rad
        atan_lut[4]  = 16'sd511;   // atan(2^-4) = 0.062419 rad
        atan_lut[5]  = 16'sd256;   // atan(2^-5) = 0.031240 rad
        atan_lut[6]  = 16'sd128;   // atan(2^-6) = 0.015624 rad
        atan_lut[7]  = 16'sd64;    // atan(2^-7) = 0.007812 rad
        atan_lut[8]  = 16'sd32;    // atan(2^-8) = 0.003906 rad
        atan_lut[9]  = 16'sd16;    // atan(2^-9) = 0.001953 rad
        atan_lut[10] = 16'sd8;     // atan(2^-10)= 0.000977 rad
        atan_lut[11] = 16'sd4;     // atan(2^-11)= 0.000488 rad
        atan_lut[12] = 16'sd2;     // atan(2^-12)= 0.000244 rad
        atan_lut[13] = 16'sd1;     // atan(2^-13)= 0.000122 rad
    end

    // -------------------------------------------------------------------------
    // Pipeline registers  (indices 0 .. ITERATIONS inclusive)
    // -------------------------------------------------------------------------
    reg signed [DATA_WIDTH-1:0] x_pipe   [0:ITERATIONS];
    reg signed [DATA_WIDTH-1:0] y_pipe   [0:ITERATIONS];
    reg signed [DATA_WIDTH-1:0] z_pipe   [0:ITERATIONS];
    reg signed [DATA_WIDTH-1:0] tgt_pipe [0:ITERATIONS]; // target sine value
    reg                          v_pipe   [0:ITERATIONS]; // valid flag

    // -------------------------------------------------------------------------
    // Stage 0 : register inputs with CORDIC initial conditions
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_pipe[0]   <= {DATA_WIDTH{1'b0}};
            y_pipe[0]   <= {DATA_WIDTH{1'b0}};
            z_pipe[0]   <= {DATA_WIDTH{1'b0}};
            tgt_pipe[0] <= {DATA_WIDTH{1'b0}};
            v_pipe[0]   <= 1'b0;
        end else begin
            x_pipe[0]   <= CORDIC_K;
            y_pipe[0]   <= {DATA_WIDTH{1'b0}};
            z_pipe[0]   <= {DATA_WIDTH{1'b0}};
            tgt_pipe[0] <= $signed(x_in);
            v_pipe[0]   <= valid_in;
        end
    end

    // -------------------------------------------------------------------------
    // Stages 1 .. ITERATIONS : pipelined CORDIC micro-rotations
    // Each stage uses only arithmetic shifts and additions (multiplier-free).
    // -------------------------------------------------------------------------
    genvar i;
    generate
        for (i = 0; i < ITERATIONS; i = i + 1) begin : cordic_stage
            // Decision bit: +1 when target >= current sine estimate
            wire d;
            assign d = (tgt_pipe[i] >= y_pipe[i]);

            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    x_pipe[i+1]   <= {DATA_WIDTH{1'b0}};
                    y_pipe[i+1]   <= {DATA_WIDTH{1'b0}};
                    z_pipe[i+1]   <= {DATA_WIDTH{1'b0}};
                    tgt_pipe[i+1] <= {DATA_WIDTH{1'b0}};
                    v_pipe[i+1]   <= 1'b0;
                end else begin
                    if (d) begin
                        // Rotate counterclockwise (increase sine)
                        x_pipe[i+1] <= x_pipe[i] - (y_pipe[i] >>> i);
                        y_pipe[i+1] <= y_pipe[i] + (x_pipe[i] >>> i);
                        z_pipe[i+1] <= z_pipe[i] + atan_lut[i];
                    end else begin
                        // Rotate clockwise (decrease sine)
                        x_pipe[i+1] <= x_pipe[i] + (y_pipe[i] >>> i);
                        y_pipe[i+1] <= y_pipe[i] - (x_pipe[i] >>> i);
                        z_pipe[i+1] <= z_pipe[i] - atan_lut[i];
                    end
                    tgt_pipe[i+1] <= tgt_pipe[i];
                    v_pipe[i+1]   <= v_pipe[i];
                end
            end
        end
    endgenerate

    // -------------------------------------------------------------------------
    // Output register
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            angle_out <= {DATA_WIDTH{1'b0}};
            valid_out <= 1'b0;
        end else begin
            angle_out <= z_pipe[ITERATIONS];
            valid_out <= v_pipe[ITERATIONS];
        end
    end

endmodule
