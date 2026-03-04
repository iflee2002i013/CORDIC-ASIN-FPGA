`timescale 1ns / 1ps
// =============================================================================
// Module  : cordic_top
// Purpose : Top-level CORDIC module exposing both arcsin and arccosine.
//
//   func_sel = 0  → output is arcsin(x_in)   (latency = ITERATIONS + 2)
//   func_sel = 1  → output is arccos(x_in)   (latency = ITERATIONS + 3)
//
//   To present a unified, single-latency interface the module pipeline-delays
//   the arcsin result by one extra register so both outputs arrive together
//   at ITERATIONS + 3 cycles after valid_in.
//
// Fixed-point format : Q2.13  (16-bit signed, scale = 2^13 = 8192)
//   x_in  ∈ [-1.0, +1.0] → integer [-8192, +8192]
//   angle ∈ [-π/2,   π ] depending on function selected
//
// Pipeline latency (both functions) : ITERATIONS + 3 clock cycles
// Throughput                         : 1 sample per clock cycle
// =============================================================================

module cordic_top #(
    parameter DATA_WIDTH = 16,
    parameter FRAC_BITS  = 13,
    parameter ITERATIONS = 14
)(
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire                   valid_in,
    input  wire                   func_sel,   // 0 = arcsin, 1 = arccos
    input  wire [DATA_WIDTH-1:0]  x_in,
    output reg                    valid_out,
    output reg  [DATA_WIDTH-1:0]  angle_out
);

    // -------------------------------------------------------------------------
    // Arcsine path
    // -------------------------------------------------------------------------
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

    // Extra register to match arccos latency (ITERATIONS + 3)
    reg [DATA_WIDTH-1:0]  asin_angle_d;
    reg                   asin_valid_d;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            asin_angle_d <= {DATA_WIDTH{1'b0}};
            asin_valid_d <= 1'b0;
        end else begin
            asin_angle_d <= asin_angle;
            asin_valid_d <= asin_valid;
        end
    end

    // -------------------------------------------------------------------------
    // Arccosine path
    // -------------------------------------------------------------------------
    wire                   acos_valid;
    wire [DATA_WIDTH-1:0]  acos_angle;

    cordic_acos #(
        .DATA_WIDTH (DATA_WIDTH),
        .FRAC_BITS  (FRAC_BITS),
        .ITERATIONS (ITERATIONS)
    ) u_acos (
        .clk       (clk),
        .rst_n     (rst_n),
        .valid_in  (valid_in),
        .x_in      (x_in),
        .valid_out (acos_valid),
        .angle_out (acos_angle)
    );

    // -------------------------------------------------------------------------
    // Pipeline-delay func_sel to align with output
    // Latency = ITERATIONS + 3 cycles; shift register covers that.
    // -------------------------------------------------------------------------
    reg [ITERATIONS+2:0] sel_pipe;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sel_pipe <= {(ITERATIONS+3){1'b0}};
        end else begin
            sel_pipe <= {sel_pipe[ITERATIONS+1:0], func_sel};
        end
    end

    wire sel_out = sel_pipe[ITERATIONS+2];

    // -------------------------------------------------------------------------
    // Output mux
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            angle_out <= {DATA_WIDTH{1'b0}};
            valid_out <= 1'b0;
        end else begin
            angle_out <= sel_out ? acos_angle  : asin_angle_d;
            valid_out <= sel_out ? acos_valid  : asin_valid_d;
        end
    end

endmodule
