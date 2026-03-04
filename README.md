# CORDIC-ASIN-FPGA

An optimized, multiplier-less CORDIC implementation for Arcsine and Arccosine
functions based on the 2023 IEEE TCAS-II paper.  
Designed for high-accuracy and low-area FPGA applications using Verilog.

---

## Repository layout

```
src/
  cordic_asin.v   – Pipelined CORDIC arcsine  (core algorithm)
  cordic_acos.v   – CORDIC arccosine          (π/2 − arcsin wrapper)
  cordic_top.v    – Top-level: both functions selected by func_sel
sim/
  tb_cordic_asin.v – Arcsine testbench
  tb_cordic_acos.v – Arccosine testbench
constraints/
  cordic.xdc       – Xilinx timing constraints (example 100 MHz)
```

---

## Algorithm

### Modified CORDIC rotation mode for arcsine

Standard CORDIC vectoring requires `sqrt(1 − x²)` as an initial condition,
which needs a multiplier.  This implementation avoids that by using the
**rotation mode with a sine-tracking decision**:

| Step | Value |
|------|-------|
| Initialise | `x₀ = Kₙ`,  `y₀ = 0`,  `z₀ = 0` |
| Decision   | `dᵢ = +1` if `target ≥ yᵢ`, else `−1` |
| Update x   | `x_{i+1} = xᵢ − dᵢ · (yᵢ >> i)` |
| Update y   | `y_{i+1} = yᵢ + dᵢ · (xᵢ >> i)` |
| Update z   | `z_{i+1} = zᵢ + dᵢ · arctan(2⁻ⁱ)` |
| Result     | `z_N ≈ arcsin(target)` |

**Why it works (no multiplier needed):**  
After N CORDIC micro-rotations the accumulated scale factor is `Kₙ⁻¹`, so  
`y_N = Kₙ⁻¹ · Kₙ · sin(z_N) = sin(z_N)`.  
Driving `y_N → target` forces `z_N = arcsin(target)`.  
All updates are **arithmetic shifts + additions only** — no multiplier.

**Arccosine** is derived in one extra pipeline stage:  
`acos(x) = π/2 − arcsin(x)`

---

## Fixed-point format

| Signal | Format | Scale | Typical range |
|--------|--------|-------|---------------|
| `x_in` | Q2.13 signed 16-bit | 8192 | [−8192, +8192] |
| `angle_out` (asin) | Q2.13 signed 16-bit | 8192 | [−12868, +12868] |
| `angle_out` (acos) | Q2.13 signed 16-bit | 8192 | [0, 25736] |

To convert: `actual_radians = integer_value / 8192`

---

## Module interfaces

### `cordic_asin`

```verilog
module cordic_asin #(
    parameter DATA_WIDTH = 16,
    parameter FRAC_BITS  = 13,
    parameter ITERATIONS = 14
)(
    input  wire clk, rst_n, valid_in,
    input  wire [DATA_WIDTH-1:0] x_in,
    output reg  valid_out,
    output reg  [DATA_WIDTH-1:0] angle_out
);
```

### `cordic_acos`

Same port list; internally instantiates `cordic_asin`.

### `cordic_top`

```verilog
module cordic_top #(...)
(
    input  wire clk, rst_n, valid_in,
    input  wire func_sel,            // 0 = arcsin, 1 = arccos
    input  wire [DATA_WIDTH-1:0] x_in,
    output reg  valid_out,
    output reg  [DATA_WIDTH-1:0] angle_out
);
```

Both functions share the same output port; `func_sel` is pipeline-delayed
to match the `ITERATIONS + 3` cycle latency of both paths.

---

## Performance (ITERATIONS = 14, DATA_WIDTH = 16)

| Metric | Value |
|--------|-------|
| Latency (arcsin) | 16 clock cycles |
| Latency (arccos) | 17 clock cycles |
| Throughput | 1 sample / cycle |
| Max error | < 0.001 rad (< 0.06°) |
| Multipliers | **0** (shifts + adds only) |

---

## Simulation

Requires [Icarus Verilog](http://iverilog.icarus.com/) (≥ 10.0).

```bash
# Arcsine testbench
iverilog -o sim/tb_cordic_asin.vvp \
    src/cordic_asin.v sim/tb_cordic_asin.v
vvp sim/tb_cordic_asin.vvp

# Arccosine testbench
iverilog -o sim/tb_cordic_acos.vvp \
    src/cordic_asin.v src/cordic_acos.v sim/tb_cordic_acos.v
vvp sim/tb_cordic_acos.vvp
```

---

## Reference

> Optimized Multiplier-less CORDIC Architecture for Arcsine and Arccosine
> Computation, *IEEE Transactions on Circuits and Systems II: Express Briefs*,
> 2023.
