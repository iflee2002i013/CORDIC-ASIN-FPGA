`timescale 1ns / 1ps
// =============================================================================
// Module  : cordic_acos
// Purpose : Multiplier-less pipelined CORDIC for arccosine computation.
//
// Method  : acos(x) = π/2 − arcsin(x)
//   Instantiates cordic_asin and subtracts its output from the Q2.13
//   representation of π/2 (= 12868) in one additional pipeline stage.
//
// Fixed-point format : Q2.13  (16-bit signed, scale = 2^13 = 8192)
//   x_in   ∈ [-1.0, +1.0]  → integer [-8192, +8192]
//   angle  ∈ [0,   π    ]  → integer [0,     25736]
//
// Pipeline latency : ITERATIONS + 3 clock cycles
// Throughput       : 1 sample per clock cycle
// =============================================================================

module cordic_acos #(
    parameter DATA_WIDTH = 16,
    parameter FRAC_BITS  = 13,
    parameter ITERATIONS = 14
)(
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire                   valid_in,
    input  wire [DATA_WIDTH-1:0]  x_in,       // cos value Q2.13 [-8192, 8192]
    output reg                    valid_out,
    output reg  [DATA_WIDTH-1:0]  angle_out   // acos(x_in) Q2.13 radians
);

    // π/2 in Q2.13 format:  1.5707963 × 8192 ≈ 12868
    localparam signed [DATA_WIDTH-1:0] PI_HALF = 16'sd12868;

    // Intermediate wires from cordic_asin
    wire                   asin_valid;
    wire [DATA_WIDTH-1:0]  asin_angle;

    cordic_asin #(
        .DATA_WIDTH (DATA_WIDTH),
        .FRAC_BITS  (FRAC_BITS),
        .ITERATIONS (ITERATIONS)
    ) u_asin (
        .clk       (clk),
        .rst_n     (rst_n),
        .valid_in  (valid_in),
        .x_in      (x_in),
        .valid_out (asin_valid),
        .angle_out (asin_angle)
    );

    // One additional pipeline stage: acos = π/2 − asin
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            angle_out <= {DATA_WIDTH{1'b0}};
            valid_out <= 1'b0;
        end else begin
            angle_out <= PI_HALF - $signed(asin_angle);
            valid_out <= asin_valid;
        end
    end

endmodule
