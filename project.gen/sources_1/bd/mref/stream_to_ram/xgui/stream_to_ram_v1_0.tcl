# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "CHANNEL" -parent ${Page_0}
  ipgui::add_param $IPINST -name "DW" -parent ${Page_0}
  ipgui::add_param $IPINST -name "IW" -parent ${Page_0}


}

proc update_PARAM_VALUE.CHANNEL { PARAM_VALUE.CHANNEL } {
	# Procedure called to update CHANNEL when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.CHANNEL { PARAM_VALUE.CHANNEL } {
	# Procedure called to validate CHANNEL
	return true
}

proc update_PARAM_VALUE.DW { PARAM_VALUE.DW } {
	# Procedure called to update DW when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DW { PARAM_VALUE.DW } {
	# Procedure called to validate DW
	return true
}

proc update_PARAM_VALUE.IW { PARAM_VALUE.IW } {
	# Procedure called to update IW when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.IW { PARAM_VALUE.IW } {
	# Procedure called to validate IW
	return true
}


proc update_MODELPARAM_VALUE.DW { MODELPARAM_VALUE.DW PARAM_VALUE.DW } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DW}] ${MODELPARAM_VALUE.DW}
}

proc update_MODELPARAM_VALUE.IW { MODELPARAM_VALUE.IW PARAM_VALUE.IW } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.IW}] ${MODELPARAM_VALUE.IW}
}

proc update_MODELPARAM_VALUE.CHANNEL { MODELPARAM_VALUE.CHANNEL PARAM_VALUE.CHANNEL } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.CHANNEL}] ${MODELPARAM_VALUE.CHANNEL}
}

