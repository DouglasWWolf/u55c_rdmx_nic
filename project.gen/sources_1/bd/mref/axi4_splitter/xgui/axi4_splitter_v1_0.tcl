# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "AR_FIFO_DEPTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "AW" -parent ${Page_0}
  ipgui::add_param $IPINST -name "AW_FIFO_DEPTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "BASE_ADDR0" -parent ${Page_0}
  ipgui::add_param $IPINST -name "BASE_ADDR1" -parent ${Page_0}
  ipgui::add_param $IPINST -name "DW" -parent ${Page_0}
  ipgui::add_param $IPINST -name "ENABLE_READ" -parent ${Page_0}
  ipgui::add_param $IPINST -name "ENABLE_WRITE" -parent ${Page_0}
  ipgui::add_param $IPINST -name "IW" -parent ${Page_0}
  ipgui::add_param $IPINST -name "OAW" -parent ${Page_0}
  ipgui::add_param $IPINST -name "R_FIFO_DEPTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "W_FIFO_DEPTH" -parent ${Page_0}


}

proc update_PARAM_VALUE.AR_FIFO_DEPTH { PARAM_VALUE.AR_FIFO_DEPTH } {
	# Procedure called to update AR_FIFO_DEPTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.AR_FIFO_DEPTH { PARAM_VALUE.AR_FIFO_DEPTH } {
	# Procedure called to validate AR_FIFO_DEPTH
	return true
}

proc update_PARAM_VALUE.AW { PARAM_VALUE.AW } {
	# Procedure called to update AW when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.AW { PARAM_VALUE.AW } {
	# Procedure called to validate AW
	return true
}

proc update_PARAM_VALUE.AW_FIFO_DEPTH { PARAM_VALUE.AW_FIFO_DEPTH } {
	# Procedure called to update AW_FIFO_DEPTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.AW_FIFO_DEPTH { PARAM_VALUE.AW_FIFO_DEPTH } {
	# Procedure called to validate AW_FIFO_DEPTH
	return true
}

proc update_PARAM_VALUE.BASE_ADDR0 { PARAM_VALUE.BASE_ADDR0 } {
	# Procedure called to update BASE_ADDR0 when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.BASE_ADDR0 { PARAM_VALUE.BASE_ADDR0 } {
	# Procedure called to validate BASE_ADDR0
	return true
}

proc update_PARAM_VALUE.BASE_ADDR1 { PARAM_VALUE.BASE_ADDR1 } {
	# Procedure called to update BASE_ADDR1 when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.BASE_ADDR1 { PARAM_VALUE.BASE_ADDR1 } {
	# Procedure called to validate BASE_ADDR1
	return true
}

proc update_PARAM_VALUE.DW { PARAM_VALUE.DW } {
	# Procedure called to update DW when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DW { PARAM_VALUE.DW } {
	# Procedure called to validate DW
	return true
}

proc update_PARAM_VALUE.ENABLE_READ { PARAM_VALUE.ENABLE_READ } {
	# Procedure called to update ENABLE_READ when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ENABLE_READ { PARAM_VALUE.ENABLE_READ } {
	# Procedure called to validate ENABLE_READ
	return true
}

proc update_PARAM_VALUE.ENABLE_WRITE { PARAM_VALUE.ENABLE_WRITE } {
	# Procedure called to update ENABLE_WRITE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ENABLE_WRITE { PARAM_VALUE.ENABLE_WRITE } {
	# Procedure called to validate ENABLE_WRITE
	return true
}

proc update_PARAM_VALUE.IW { PARAM_VALUE.IW } {
	# Procedure called to update IW when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.IW { PARAM_VALUE.IW } {
	# Procedure called to validate IW
	return true
}

proc update_PARAM_VALUE.OAW { PARAM_VALUE.OAW } {
	# Procedure called to update OAW when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.OAW { PARAM_VALUE.OAW } {
	# Procedure called to validate OAW
	return true
}

proc update_PARAM_VALUE.R_FIFO_DEPTH { PARAM_VALUE.R_FIFO_DEPTH } {
	# Procedure called to update R_FIFO_DEPTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.R_FIFO_DEPTH { PARAM_VALUE.R_FIFO_DEPTH } {
	# Procedure called to validate R_FIFO_DEPTH
	return true
}

proc update_PARAM_VALUE.W_FIFO_DEPTH { PARAM_VALUE.W_FIFO_DEPTH } {
	# Procedure called to update W_FIFO_DEPTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.W_FIFO_DEPTH { PARAM_VALUE.W_FIFO_DEPTH } {
	# Procedure called to validate W_FIFO_DEPTH
	return true
}


proc update_MODELPARAM_VALUE.DW { MODELPARAM_VALUE.DW PARAM_VALUE.DW } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DW}] ${MODELPARAM_VALUE.DW}
}

proc update_MODELPARAM_VALUE.AW { MODELPARAM_VALUE.AW PARAM_VALUE.AW } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.AW}] ${MODELPARAM_VALUE.AW}
}

proc update_MODELPARAM_VALUE.IW { MODELPARAM_VALUE.IW PARAM_VALUE.IW } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.IW}] ${MODELPARAM_VALUE.IW}
}

proc update_MODELPARAM_VALUE.OAW { MODELPARAM_VALUE.OAW PARAM_VALUE.OAW } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.OAW}] ${MODELPARAM_VALUE.OAW}
}

proc update_MODELPARAM_VALUE.ENABLE_WRITE { MODELPARAM_VALUE.ENABLE_WRITE PARAM_VALUE.ENABLE_WRITE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ENABLE_WRITE}] ${MODELPARAM_VALUE.ENABLE_WRITE}
}

proc update_MODELPARAM_VALUE.ENABLE_READ { MODELPARAM_VALUE.ENABLE_READ PARAM_VALUE.ENABLE_READ } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ENABLE_READ}] ${MODELPARAM_VALUE.ENABLE_READ}
}

proc update_MODELPARAM_VALUE.AW_FIFO_DEPTH { MODELPARAM_VALUE.AW_FIFO_DEPTH PARAM_VALUE.AW_FIFO_DEPTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.AW_FIFO_DEPTH}] ${MODELPARAM_VALUE.AW_FIFO_DEPTH}
}

proc update_MODELPARAM_VALUE.AR_FIFO_DEPTH { MODELPARAM_VALUE.AR_FIFO_DEPTH PARAM_VALUE.AR_FIFO_DEPTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.AR_FIFO_DEPTH}] ${MODELPARAM_VALUE.AR_FIFO_DEPTH}
}

proc update_MODELPARAM_VALUE.W_FIFO_DEPTH { MODELPARAM_VALUE.W_FIFO_DEPTH PARAM_VALUE.W_FIFO_DEPTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.W_FIFO_DEPTH}] ${MODELPARAM_VALUE.W_FIFO_DEPTH}
}

proc update_MODELPARAM_VALUE.R_FIFO_DEPTH { MODELPARAM_VALUE.R_FIFO_DEPTH PARAM_VALUE.R_FIFO_DEPTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.R_FIFO_DEPTH}] ${MODELPARAM_VALUE.R_FIFO_DEPTH}
}

proc update_MODELPARAM_VALUE.BASE_ADDR0 { MODELPARAM_VALUE.BASE_ADDR0 PARAM_VALUE.BASE_ADDR0 } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.BASE_ADDR0}] ${MODELPARAM_VALUE.BASE_ADDR0}
}

proc update_MODELPARAM_VALUE.BASE_ADDR1 { MODELPARAM_VALUE.BASE_ADDR1 PARAM_VALUE.BASE_ADDR1 } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.BASE_ADDR1}] ${MODELPARAM_VALUE.BASE_ADDR1}
}

