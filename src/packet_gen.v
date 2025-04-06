//====================================================================================
//                        ------->  Revision History  <------
//====================================================================================
//
//   Date     Who   Ver  Changes
//====================================================================================
// 20-Mar-25  DWW     1  Initial creation
//====================================================================================

/*

   This generates a specified number of RDMX packets.  All packets have a payload
   size 4K, and are targeted at PCI addresses between 0x1_0000_0000 and 0x1_FFFF_FFFF.

    The contents of the packets are repetitions of a 32-bit counter.  The high order
    32-bits of the RDMX packet header (which is normally reserved) has been replaced
    with this 32-bit counter.

    Packets are generated in groups of 4, with 65*4 empty clock-cycles between each
    group of 4.  This gives us an effective bandwidth of about 50% of the maximum
    possible bandwidth.   On a 250 MHz bus, this works out to about 8 GB/sec.

*/

module packet_gen
(
    input             clk, resetn,

    input             start,
    input[63:0]       max_packets,
    output            idle,

    output reg[511:0] axis_tdata,
    output            axis_tvalid,
    output            axis_tuser,
    output            axis_tlast,
    input             axis_tready
);

localparam PAYLOAD_SIZE = 4096;
localparam LAST_CYCLE   = (PAYLOAD_SIZE / 64) + 1;

reg[ 31:0] sequence_num;
reg[ 63:0] packet_count;

// Contains a little-endian version of the RDMX header
wire[511:0] le_rdmx_header;

// This is true on any data-cycle where a data-transfer took place
wire xfer = axis_tvalid & axis_tready;

//=============================================================================
// This block manages the PCI address where the packet should be written
//=============================================================================
reg[31:0] pci_address;
//-----------------------------------------------------------------------------
always @(posedge clk) begin

    if (resetn == 0 || start)
        pci_address <= 0;
    else if (xfer & axis_tlast)
        pci_address <= pci_address + PAYLOAD_SIZE;

end
//=============================================================================


//=============================================================================
// This block tracks the data-cycle number (1 thru 65) within the packet
//=============================================================================
reg[ 7:0] cycle_within_packet;
//-----------------------------------------------------------------------------
always @(posedge clk) begin
    if (resetn == 0 || start) begin
        cycle_within_packet <= 1;
    end

    else if (xfer) begin
        if (cycle_within_packet == LAST_CYCLE)
            cycle_within_packet <= 1;
        else
            cycle_within_packet <= cycle_within_packet + 1;
    end
end
//=============================================================================


//=============================================================================
// Increment "sequence number" after every data transfer
//=============================================================================
always @(posedge clk) begin

    if (resetn == 0 || start)
        sequence_num <= 0;
    else if (xfer)
        sequence_num <= sequence_num + 1;
end
//=============================================================================


//=============================================================================
// Generate the requested number of 65-cycle packets, with a 65*4 cycle
// pause after every four packets
//=============================================================================
reg[ 1:0] fsm_state;
reg[15:0] countdown;
//-----------------------------------------------------------------------------
always @(posedge clk) begin

    if (countdown) countdown <= countdown - 1;

    if (resetn == 0) begin
        fsm_state <= 0;
    end
    
    else case(fsm_state)

        // Here we wait for someone to tell us to start
        0:  if (start) begin
                packet_count <= 1;
                fsm_state    <= 1;
            end

        // On the last cycle of each packet...
        1:  if (xfer & axis_tlast) begin
                
                if (packet_count >= max_packets)
                    fsm_state <= 0;
                
                else if (packet_count[1:0] == 0) begin
                    countdown <= LAST_CYCLE * 4;
                    fsm_state <= 2;
                end

                packet_count <= packet_count + 1;    
            end


        // Here we're wasting time between packet groups
        2:  if (countdown == 0) fsm_state <= 1;

    endcase

end
//=============================================================================

// "idle" is true when we 
assign idle = (fsm_state == 0) & (start == 0);

// TLAST is asserted on the final cycle of every packet
assign axis_tlast  = (cycle_within_packet == LAST_CYCLE) & axis_tvalid;

// When we're in fsm_state 1, we are outputting packet data
assign axis_tvalid = (fsm_state == 1);

// A CMAC uses this to indicates "bad packet".  All of our packets are good.
assign axis_tuser = 0;


//=============================================================================
// Ensure that an RDMX header is present on the 1st cycle of each packet
//=============================================================================
always @* begin
    if (cycle_within_packet == 1)
        axis_tdata = {sequence_num, le_rdmx_header[60*8-1:0]};
    else
        axis_tdata = {sequence_num, {15{sequence_num}}};
end
//=============================================================================


//=============================================================================
// This encodes an RDMX header into field "le_rdmx_header"
//=============================================================================
rdmx_encoder i_encoder
(
    .rdmx_target_addr({32'h0, pci_address}),
    .payload_length  (PAYLOAD_SIZE        ),
    .le_rdmx_header  (le_rdmx_header      )
);
//=============================================================================

endmodule