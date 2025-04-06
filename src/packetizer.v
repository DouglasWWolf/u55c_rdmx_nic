//====================================================================================
//                        ------->  Revision History  <------
//====================================================================================
//
//   Date     Who   Ver  Changes
//====================================================================================
// 20-Mar-25  DWW     1  Initial creation
//====================================================================================

/*
    This converts an incoming AXI stream into packets by adding a TLAST signal
*/


module packetizer # (parameter DW=512)
(
    input   clk, resetn,

    // This is the number of cycles we want in an output packet
    input[7:0]          packet_cycles,

    // The input bus
    input[DW-1:0]       axis_in_tdata,
    input               axis_in_tvalid,
    output              axis_in_tready,

    // The output bus
    output [DW-1:0]     axis_out_tdata,
    output [(DW/8)-1:0] axis_out_tkeep,
    output              axis_out_tlast,
    output              axis_out_tvalid,
    input               axis_out_tready

);

// This counts cycles of the packet
reg[7:0] cycle;

always @(posedge clk) begin
    if (resetn == 0)
        cycle <= 1;

    else if (axis_in_tvalid & axis_in_tready) begin
        if (cycle == packet_cycles)
            cycle <= 1;
        else
            cycle <= cycle + 1;
    end
end

// Connect the input bus to the output bus
assign axis_out_tdata  = axis_in_tdata;
assign axis_out_tkeep  = -1;
assign axis_out_tlast  = (cycle == packet_cycles);
assign axis_out_tvalid = axis_in_tvalid;
assign axis_in_tready  = axis_out_tready;


endmodule
