# =============================================================================
# Xilinx XDC Constraints for cordic_top
# Target: Xilinx 7-Series / UltraScale (adjust part and pin assignments)
# =============================================================================

# ----------------------------------------------------------------------------
# Clock definition (example: 100 MHz system clock on W5 for Basys3)
# ----------------------------------------------------------------------------
create_clock -period 10.000 -name sys_clk [get_ports clk]

set_input_delay  -clock sys_clk 2.0 [get_ports {x_in[*] valid_in func_sel}]
set_output_delay -clock sys_clk 2.0 [get_ports {angle_out[*] valid_out}]

# ----------------------------------------------------------------------------
# Timing: all paths are registered-to-registered inside the CORDIC pipeline;
# no multicycle paths needed.
# ----------------------------------------------------------------------------
set_false_path -from [get_ports rst_n]
