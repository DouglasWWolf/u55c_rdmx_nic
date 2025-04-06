#
# The Alveo X55C FPGA is xcvu47p-fsvh2892-2L-e
#

#
# Compress the bitstream, these things are huge!
#
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]


#
# CATTRIP - Catastrophic power trip.  If HBMs are present this is fed by the HBMs CATTRIP signal.
#           This must be a zero for the board to operate.   A one here shuts down the internal power
#
set_property -dict {PACKAGE_PIN BE45  IOSTANDARD LVCMOS18} [get_ports hbm_cattrip]


#
# PCIe0 RefClk
#
# PCIe0 is: Block X1Y0
#           Quad  227
#
set_property PACKAGE_PIN AL15                   [get_ports pcie0_refclk_clk_p]
set_property PACKAGE_PIN AL14                   [get_ports pcie0_refclk_clk_n]
create_clock -period 10.000 -name pcie0_sys_clk [get_ports pcie0_refclk_clk_p]
set_clock_groups -group [get_clocks pcie0_sys_clk -include_generated_clocks] -asynchronous


#
# PCIe1 RefClk
#
# PCIe1 is: Block X1Y1
#           Quad  225
#
#set_property PACKAGE_PIN AR15                   [get_ports pcie1_refclk_clk_p]
#set_property PACKAGE_PIN AR14                   [get_ports pcie1_refclk_clk_n]
#create_clock -period 10.000 -name pcie1_sys_clk [get_ports pcie1_refclk_clk_p]
#set_clock_groups -group [get_clocks pcie1_sys_clk -include_generated_clocks] -asynchronous


#
# pcie reset signal from the host PC 
#
#set_property -dict {PACKAGE_PIN BF41  IOSTANDARD LVCMOS18} [get_ports pcie_perst_l]


#
# LED status lights, usually used for QSFP status
#
set_property -dict {PACKAGE_PIN BL13  IOSTANDARD LVCMOS18}  [get_ports qsfp0_leds[0]] ;# Activity
set_property -dict {PACKAGE_PIN BK11  IOSTANDARD LVCMOS18}  [get_ports qsfp0_leds[1]] ;# Link-status, green
set_property -dict {PACKAGE_PIN BJ11  IOSTANDARD LVCMOS18}  [get_ports qsfp0_leds[2]] ;# Link-status, yellow
#set_property -dict {PACKAGE_PIN BK14  IOSTANDARD LVCMOS18}  [get_ports qsfp1_leds[0]] ;# Activity
#set_property -dict {PACKAGE_PIN BK15  IOSTANDARD LVCMOS18}  [get_ports qsfp1_leds[1]] ;# Link-status, green
#set_property -dict {PACKAGE_PIN BL12  IOSTANDARD LVCMOS18}  [get_ports qsfp1_leds[2]] ;# Link-Status, yellow


#
# QSFP_0 Reference Clock, 161.1328125 MHz
#
# QSFP_0 is: CMAC Block X0Y3
#            GT Group   X0Y24 ~ X0Y27 (Bank 130)
#            The right or top QSFP port
#
set_property PACKAGE_PIN AD43 [get_ports "qsfp0_clk_clk_n"] 
set_property PACKAGE_PIN AD42 [get_ports "qsfp0_clk_clk_p"]



#
# QSFP_1 Reference Clock, 161.1328125 MHz
#
# QSFP_1 is: CMAC Block X0Y4
#            GT Group   X0Y28 ~ X0Y31 (Bank 131)
#            The left or bottom QSFP port
#
#set_property PACKAGE_PIN AB43 [get_ports "qsfp1_clk_clk_n"] 
#set_property PACKAGE_PIN AB42 [get_ports "qsfp1_clk_clk_p"]



#
# HBM_0 Reference Clock, 100 Mhz
#
#set_property -dict {PACKAGE_PIN BK10  IOSTANDARD LVDS}  [get_ports hbm0_refclock_clk_p]
#set_property -dict {PACKAGE_PIN BL10  IOSTANDARD LVDS}  [get_ports hbm0_refclock_clk_n]
#create_clock -period 10.000 -name HBM0_REFCLK           [get_ports hbm0_refclock_clk_p]



#
# HBM_1 Reference Clock, 100 Mhz
#
#set_property -dict {PACKAGE_PIN BK43  IOSTANDARD LVDS}  [get_ports hbm1_refclock_clk_p]
#set_property -dict {PACKAGE_PIN BK44  IOSTANDARD LVDS}  [get_ports hbm1_refclock_clk_n]
#create_clock -period 10.000 -name HBM1_REFCLK           [get_ports hbm1_refclock_clk_p]

