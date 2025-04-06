//====================================================================================
//                        ------->  Revision History  <------
//====================================================================================
//
//   Date     Who   Ver  Changes
//====================================================================================
// 20-Mar-25  DWW     1  Initial creation
//====================================================================================

/*
    This determines the size of stream packets (in clock cycles) and writes
    that value to a port
*/

module packet_sizer # (parameter DW=512)
(
    input            clk, resetn,

    output reg[7:0]  packet_cycles,

    (* X_INTERFACE_MODE = "monitor" *)
    input[DW-1:0]    axis_tdata,
    input            axis_tlast,
    input            axis_tvalid,
    input            axis_tready
);


reg[7:0] counter;

always @(posedge clk) begin

    if (resetn == 0) begin
        counter       <= 0;
        packet_cycles <= 0;
    end

    else if (axis_tvalid & axis_tready) begin
        if (axis_tlast == 0)
            counter <= counter + 1;
        else begin
            packet_cycles <= counter + 1;
            counter <= 0;
        end
    end

end


endmodule

