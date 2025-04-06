//====================================================================================
//                        ------->  Revision History  <------
//====================================================================================
//
//   Date     Who   Ver  Changes
//====================================================================================
// 17-Mar-25  DWW     1  Initial creation
//====================================================================================

/*
    Multiplexes two AXI stream inputs into a single output
*/

module eth_tx_mux # (parameter DW=512)
(
    
    // This doesn't do anything and is here to keep Vivado happy
    input clk,

    // 0 selects "axis_xmit" input, 1 selects "axis_loop" input
    input port_select,

    input[DW-1:0]      axis_loop_tdata,
    input              axis_loop_tlast,
    input              axis_loop_tvalid,
    output reg         axis_loop_tready,

    input[DW-1:0]      axis_xmit_tdata,
    input              axis_xmit_tlast,
    input              axis_xmit_tvalid,
    output reg         axis_xmit_tready,

    output reg[DW-1:0] axis_out_tdata,
    output reg         axis_out_tlast,
    output reg         axis_out_tvalid,
    input              axis_out_tready
);

// This mux ensures that only one of the input streams is ever connected
// to the output stream at any given time.   When data arrives from the
// non-selected input, it will be ignored.
always @* begin

    // Pass "axis_xmit" to "axis_out"
    if (port_select == 0) begin
        axis_out_tvalid  = axis_xmit_tvalid;
        axis_out_tdata   = axis_xmit_tdata;
        axis_out_tlast   = axis_xmit_tlast;
        axis_xmit_tready = axis_out_tready;
        axis_loop_tready = 1; 
    end

    // Pass "axis_loop" to "axis_out"
    else begin
        axis_out_tvalid  = axis_loop_tvalid;
        axis_out_tdata   = axis_loop_tdata;
        axis_out_tlast   = axis_loop_tlast;
        axis_loop_tready = axis_out_tready;
        axis_xmit_tready = 1; 
    end
   
end



endmodule

