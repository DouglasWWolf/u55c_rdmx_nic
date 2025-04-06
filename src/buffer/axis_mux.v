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

    Assumes that only one input stream will be active at a time

*/

module axis_mux # (parameter DW=512)
(
    
    // This doesn't do anything and is here to keep Vivado happy
    input clk,

    input[DW-1:0]      axis0_tdata,
    input              axis0_tlast,
    input              axis0_tvalid,
    output reg         axis0_tready,

    input[DW-1:0]      axis1_tdata,
    input              axis1_tlast,
    input              axis1_tvalid,
    output reg         axis1_tready,

    output reg[DW-1:0] axis_out_tdata,
    output reg         axis_out_tlast,
    output reg         axis_out_tvalid,
    input              axis_out_tready
);

// This mux ensures that only one of the input streams is ever connected
// to the output stream at any given time.  
always @* begin

    if (axis0_tvalid) begin
        axis_out_tvalid = 1;
        axis_out_tdata  = axis0_tdata;
        axis_out_tlast  = axis0_tlast;
        axis0_tready    = axis_out_tready;
        axis1_tready    = 0;
    end

    else if (axis1_tvalid) begin
        axis_out_tvalid = 1;
        axis_out_tdata  = axis1_tdata;
        axis_out_tlast  = axis1_tlast;
        axis0_tready    = 0;
        axis1_tready    = axis_out_tready;
    end

    else begin
        axis_out_tvalid = 0;
        axis_out_tdata  = 0;
        axis_out_tlast  = 0;
        axis0_tready    = 0;
        axis1_tready    = 0;
    end

end



endmodule

