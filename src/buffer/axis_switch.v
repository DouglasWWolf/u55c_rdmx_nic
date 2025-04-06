//====================================================================================
//                        ------->  Revision History  <------
//====================================================================================
//
//   Date     Who   Ver  Changes
//====================================================================================
// 17-Mar-25  DWW     1  Initial creation
//====================================================================================

/*
    Accepts an AXI-stream input and directs it to one of two AXI-stream outputs
*/

module axis_switch # (parameter DW=512)
(
    
    // This doesn't do anything and is here to keep Vivado happy
    input clk,

    // This selects which output is connected to the input
    input port_select,

    // Strobes high for one cycle every time we see a packet
    output packet_strb,

    // The input stream
    input[DW-1:0] axis_in_tdata,
    input         axis_in_tlast,
    input         axis_in_tvalid,
    output        axis_in_tready,

    // Output steam #0
    output[DW-1:0] axis_out0_tdata,
    output         axis_out0_tlast,
    output         axis_out0_tvalid,
    input          axis_out0_tready,

    // Output steam #1
    output[DW-1:0] axis_out1_tdata,
    output         axis_out1_tlast,
    output         axis_out1_tvalid,
    input          axis_out1_tready
);

// Connect the TDATA input to the TDATA outputs
assign axis_out0_tdata = axis_in_tdata;
assign axis_out1_tdata = axis_in_tdata;

// The output TLAST lines are driven from the input TVALID line
assign axis_out0_tlast = axis_in_tlast & (port_select == 0);
assign axis_out1_tlast = axis_in_tlast & (port_select == 1);

// The output TVALID lines are driven from the input TVALID line
assign axis_out0_tvalid = axis_in_tvalid & (port_select == 0);
assign axis_out1_tvalid = axis_in_tvalid & (port_select == 1);

// The input TREADY signal is ready when the output TREADY signal is ready
assign axis_in_tready = (port_select == 0) ? axis_out0_tready : axis_out1_tready;

// This strobes high for one cycle at the end of every packet
assign packet_strb = axis_in_tvalid & axis_in_tready & axis_in_tlast;

endmodule



