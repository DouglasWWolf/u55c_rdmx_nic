//====================================================================================
//                        ------->  Revision History  <------
//====================================================================================
//
//   Date     Who   Ver  Changes
//====================================================================================
// 17-Mar-25  DWW     1  Initial creation
//====================================================================================

/*
   Controls the switch that determines which datapath incoming QSFP data streams into
*/


module switch_ctrl
(
    input      clk, resetn,

    output reg inflow_q,

    input      has_data0, has_data1,

    input      inflow_done0, inflow_done1,

    input      ram_reader_idle0, ram_reader_idle1,

    output     ram_reader_start0, ram_reader_start1
);

wire[1:0] inflow_done;
assign inflow_done[0] = inflow_done0;
assign inflow_done[1] = inflow_done1;

wire[1:0] has_data;
assign has_data[0] = has_data0;
assign has_data[1] = has_data1;

wire[1:0] ram_reader_idle;
assign ram_reader_idle[0] = ram_reader_idle0;
assign ram_reader_idle[1] = ram_reader_idle1;

reg[1:0] ram_reader_start;
assign ram_reader_start0 = ram_reader_start[0];
assign ram_reader_start1 = ram_reader_start[1];

wire other_q = ~inflow_q;

reg fsm_state;
always @(posedge clk) begin

    // These will strobe high for just 1 cycle at a time
    ram_reader_start <= 0;

    if (resetn == 0) begin
        inflow_q  <= 0;
        fsm_state <= 0;
    end 

    else case(fsm_state)

        // If we have data, begin inflow on the other queue
        0:  if (ram_reader_idle[other_q] & has_data[inflow_q]) begin
                inflow_q  <= ~inflow_q;
                fsm_state <= 1;
            end

        // If all inflowing data is committed to RAM, start 
        // reading the data out of RAM and streaming it to 
        // the output
        1:  if (inflow_done[other_q]) begin
                ram_reader_start[other_q] <= 1;
                fsm_state <= 0;
            end

    endcase

end

endmodule