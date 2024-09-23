set_property -dict {PACKAGE_PIN AJ21 IOSTANDARD LVCMOS18} [get_ports CAN_0_rx]
set_property -dict {PACKAGE_PIN Y20 IOSTANDARD LVCMOS18} [get_ports CAN_0_tx]

set_property -dict {PACKAGE_PIN AK21 IOSTANDARD LVCMOS18} [get_ports CAN_1_rx]
set_property -dict {PACKAGE_PIN AA20 IOSTANDARD LVCMOS18} [get_ports CAN_1_tx]

set_property -dict {PACKAGE_PIN AK25 IOSTANDARD LVCMOS18} [get_ports IRQ_F2P_0]

set_property -dict {PACKAGE_PIN AB21 IOSTANDARD LVCMOS18} [get_ports UART_0_rxd]
set_property -dict {PACKAGE_PIN AC18 IOSTANDARD LVCMOS18} [get_ports UART_0_txd]

set_property -dict {PACKAGE_PIN AB16 IOSTANDARD LVCMOS18} [get_ports txd]
set_property -dict {PACKAGE_PIN AC19 IOSTANDARD LVCMOS18} [get_ports rxd]

set_property -dict {PACKAGE_PIN Y21 IOSTANDARD LVCMOS18} [get_ports gpio_rtl_tri_o]
set_property -dict {PACKAGE_PIN K15 IOSTANDARD LVCMOS18} [get_ports key]
set_property -dict {PACKAGE_PIN W21 IOSTANDARD LVCMOS18} [get_ports m00_axi_txn_done]
set_property -dict {PACKAGE_PIN A17 IOSTANDARD LVCMOS18} [get_ports m00_axi_error]

set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
