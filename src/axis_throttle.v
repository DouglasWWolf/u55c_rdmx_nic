//====================================================================================
//                        ------->  Revision History  <------
//====================================================================================
//
//   Date     Who   Ver  Changes
//====================================================================================
// 17-Mar-25  DWW     1  Initial creation
//====================================================================================

/*
   Provides a way to pause an AXI stream
*/


module axis_throttle # (DW=512)
(
    // This doesn't do anything, it's here to keep Vivado happy
    input   clk, 

    // Assert this to pause the output
    input pause,

    // The input bus
    input[DW-1:0]   axis_in_tdata,
    input           axis_in_tlast,
    input           axis_in_tvalid,
    output          axis_in_tready,

    // The output bus
    output[DW-1:0]   axis_out_tdata,
    output           axis_out_tlast,
    output           axis_out_tvalid,
    input            axis_out_tready
);

assign axis_out_tdata  = axis_in_tdata;
assign axis_out_tlast  = axis_in_tlast;
assign axis_out_tvalid = axis_in_tvalid  & (pause == 0);
assign axis_in_tready  = axis_out_tready & (pause == 0);

endmodule