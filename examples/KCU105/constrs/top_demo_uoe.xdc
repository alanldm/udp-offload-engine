#clock creation section

# 125 MHz global ref - defined in clock wiz
# create_clock -period 8.000 [get_ports CLK_125_P]
#  156.25 MHz SFP ref
create_clock -period 6.400 [get_ports SFP_REFCLK_P]

# Pinout

# Bank  66 VCCO - VADJ_1V8_FPGA_10A - IO_L12P_T1U_N10_GC_66
set_property IOSTANDARD LVDS [get_ports CLK_125_P]
set_property PACKAGE_PIN G10 [get_ports CLK_125_P]
set_property PACKAGE_PIN F10 [get_ports CLK_125_N]
set_property IOSTANDARD LVDS [get_ports CLK_125_N]

# SFP GT in bank 226 sourced by Si570 clock in Bank 227
set_property PACKAGE_PIN P6 [get_ports SFP_REFCLK_P]
set_property PACKAGE_PIN P5 [get_ports SFP_REFCLK_N]

# SFP 2
set_property PACKAGE_PIN W4 [get_ports SFP_TX_P]
set_property PACKAGE_PIN W3 [get_ports SFP_TX_N]
set_property PACKAGE_PIN V2 [get_ports SFP_RX_P]
set_property PACKAGE_PIN V1 [get_ports SFP_RX_N]

set_property PACKAGE_PIN AM9     [get_ports SFP_LOS]
set_property IOSTANDARD LVCMOS18 [get_ports SFP_LOS]

# GPIO Button for reset
set_property PACKAGE_PIN AE10    [get_ports CPU_RESET]
set_property IOSTANDARD LVCMOS18 [get_ports CPU_RESET]

# UART
# Bank  95 VCCO -          - IO_L3P_T0L_N4_AD15P_A26_65
set_property PACKAGE_PIN G25      [get_ports "UART_RX"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "UART_RX"]
# Bank  95 VCCO -          - IO_L2P_T0L_N2_FOE_B_65
set_property PACKAGE_PIN K26      [get_ports "UART_TX"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "UART_TX"]
# Inversion RX/TX sur carte d'évaluation 
