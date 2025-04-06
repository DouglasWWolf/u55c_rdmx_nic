//====================================================================================
//                        ------->  Revision History  <------
//====================================================================================
//
//   Date     Who   Ver  Changes
//====================================================================================
// 20-Mar-25  DWW     1  Initial creation
//====================================================================================

/*
   This accepts an AXI-stream full of RDMX packets and writes the payloads
   of those packets to an AXI4MM master bus.

   The first data-cycle of every packet is assumed to be an RDMX header.  From
   that header, we compute the PCI address to store the payload at as well as
   the number of data-cycles in the packet payload.
*/


module rdmx_to_pci # (parameter DW=512)
(
    input           clk, resetn,

    // The base address and size of the reserved contiguous buffer in host RAM
    input[63:00]    pci_base, pci_size,

    // Strobes high for one cycle when we see an invalid RDMX offset
    output          pci_range_err_strb,

    // The input stream
    input[DW-1:0]   AXIS_IN_TDATA,
    input           AXIS_IN_TVALID,
    output          AXIS_IN_TREADY,

    //=================   This is the AXI4 output interface   ==================

    // "Specify write address"              -- Master --    -- Slave --
    output     [63:0]                        M_AXI_AWADDR,
    output     [7:0]                         M_AXI_AWLEN,
    output     [2:0]                         M_AXI_AWSIZE,
    output     [3:0]                         M_AXI_AWID,
    output     [1:0]                         M_AXI_AWBURST,
    output                                   M_AXI_AWLOCK,
    output     [3:0]                         M_AXI_AWCACHE,
    output     [3:0]                         M_AXI_AWQOS,
    output     [2:0]                         M_AXI_AWPROT,
    output                                   M_AXI_AWVALID,
    input                                                   M_AXI_AWREADY,

    // "Write Data"                         -- Master --    -- Slave --
    output [DW-1:0]                         M_AXI_WDATA,
    output [(DW/8)-1:0]                     M_AXI_WSTRB,
    output                                  M_AXI_WVALID,
    output                                  M_AXI_WLAST,
    input                                                   M_AXI_WREADY,

    // "Send Write Response"                -- Master --    -- Slave --
    input[1:0]                                              M_AXI_BRESP,
    input                                                   M_AXI_BVALID,
    output                                  M_AXI_BREADY,

    // "Specify read address"               -- Master --    -- Slave --
    output[63:0]                            M_AXI_ARADDR,
    output                                  M_AXI_ARVALID,
    output[2:0]                             M_AXI_ARPROT,
    output                                  M_AXI_ARLOCK,
    output[3:0]                             M_AXI_ARID,
    output[7:0]                             M_AXI_ARLEN,
    output[2:0]                             M_AXI_ARSIZE,
    output[1:0]                             M_AXI_ARBURST,
    output[3:0]                             M_AXI_ARCACHE,
    output[3:0]                             M_AXI_ARQOS,
    input                                                   M_AXI_ARREADY,

    // "Read data back to master"           -- Master --    -- Slave --
    input[DW-1:0]                                           M_AXI_RDATA,
    input                                                   M_AXI_RVALID,
    input[1:0]                                              M_AXI_RRESP,
    input                                                   M_AXI_RLAST,
    output                                  M_AXI_RREADY
    //==========================================================================



);

reg [ 7:0] cycle_within_packet;
wire[ 7:0] imm_payload_cycles;
reg [ 7:0] payload_cycles;
wire[63:0] rdmx_offset;
reg [63:0] pci_address;
wire[ 7:0] awlen = imm_payload_cycles - 1;

// This will be true on any input data-cycle that contains an RDMX header
wire is_header = (cycle_within_packet == 0) & AXIS_IN_TVALID;

// This is the last offset into the host RAM buffer that the current packet will occupy
wire[63:0] last_offset = rdmx_offset + imm_payload_cycles*64 - 1;

// Determine if the RDMX target address is outside of our legal range
wire out_of_range = (last_offset > pci_size);

// This will strobe high for one cycle any time a range error occurs
assign pci_range_err_strb = is_header & out_of_range;

 //=============================================================================
// This ensures that pci_address is always within a valid range
//=============================================================================
always @* begin
    if (out_of_range)
        pci_address = pci_base;
    else
        pci_address = pci_base + rdmx_offset;
end
//=============================================================================


// This is the TREADY signal from the input side of the packet-data FIFO
wire pdf_in_tready;

// This is the TVALID signal to the input side of the packet-data FIFO
wire pdf_in_tvalid = (cycle_within_packet != 0) & AXIS_IN_TVALID;

// We are always ready to accept input when we're waiting for an RDMX header
assign AXIS_IN_TREADY = is_header | pdf_in_tready;

// This will be high on the last cycle of an input packet
wire pdf_in_tlast = (cycle_within_packet == payload_cycles);

// If we're not in reset, we are ready to receive B-channel acknowledgements
assign M_AXI_BREADY = (resetn != 0);


//=============================================================================
// This block monitors the input stream and keeps track of which data-cycles
// are RDMX headers and which ones are payload data.
//
// Payload data gets written to the packet_data_fifo.
// Packet length (in cycles) and RDMX address gets written to the aw_fifo.
//=============================================================================
always @(posedge clk) begin
    
    if (resetn == 0) begin
        cycle_within_packet <= 0;
    end

    else if (AXIS_IN_TVALID & AXIS_IN_TREADY) begin
        if (cycle_within_packet == 0) begin
            payload_cycles      <= imm_payload_cycles;
            cycle_within_packet <= 1;
        end

        else if (cycle_within_packet == payload_cycles)
            cycle_within_packet <= 0;
        
        else
            cycle_within_packet <= cycle_within_packet + 1;
    end

end
//=============================================================================



//=============================================================================
// Constant values for M_AXI ports associated with AXI write operations
//=============================================================================
assign M_AXI_AWSIZE  = $clog2(DW/8);
assign M_AXI_AWID    = 0;
assign M_AXI_AWBURST = 1;
assign M_AXI_AWLOCK  = 0;
assign M_AXI_AWCACHE = 0;
assign M_AXI_AWQOS   = 0;
assign M_AXI_AWPROT  = 0;

assign M_AXI_WSTRB   = -1;
//=============================================================================


//=============================================================================
// We won't be using the "read" side of the output bus
//=============================================================================
assign M_AXI_ARADDR  = 0;
assign M_AXI_ARVALID = 0;
assign M_AXI_ARPROT  = 0;
assign M_AXI_ARLOCK  = 0;
assign M_AXI_ARID    = 0;
assign M_AXI_ARLEN   = 0;
assign M_AXI_ARSIZE  = 0;
assign M_AXI_ARBURST = 0;
assign M_AXI_ARCACHE = 0;
assign M_AXI_ARQOS   = 0;
assign M_AXI_RREADY  = 0; 
//=============================================================================



//=============================================================================
// This decodes an RDMX header into a target address and a payload length
//=============================================================================
rdmx_decoder i_decoder
(
    .le_rdmx_header(AXIS_IN_TDATA     ),
    .rdmx_address  (rdmx_offset       ),
    .payload_bytes (                  ),
    .payload_cycles(imm_payload_cycles)
);
//=============================================================================


//=============================================================================
// This FIFO holds incoming packet-data
//=============================================================================
xpm_fifo_axis #
(
   .FIFO_DEPTH      (256),
   .TDATA_WIDTH     (DW),
   .FIFO_MEMORY_TYPE("auto"),
   .PACKET_FIFO     ("false"),
   .USE_ADV_FEATURES("0000"),
   .CLOCKING_MODE   ("common_clock")
)
packet_data_fifo
(
    // Clock and reset
   .s_aclk   (clk   ),
   .m_aclk   (clk   ),
   .s_aresetn(resetn),

    // The input bus to the FIFO comes straight from the AXIS_IN input stream
   .s_axis_tdata (AXIS_IN_TDATA ),
   .s_axis_tvalid(pdf_in_tvalid ),
   .s_axis_tlast (pdf_in_tlast  ),
   .s_axis_tready(pdf_in_tready ),

    // The output bus of the FIFO
   .m_axis_tdata (M_AXI_WDATA  ),
   .m_axis_tlast (M_AXI_WLAST  ),
   .m_axis_tvalid(M_AXI_WVALID ),
   .m_axis_tready(M_AXI_WREADY ),

    // Unused input stream signals
   .s_axis_tkeep(),
   .s_axis_tdest(),
   .s_axis_tid  (),
   .s_axis_tstrb(),
   .s_axis_tuser(),

    // Unused output stream signals
   .m_axis_tdest(),
   .m_axis_tid  (),
   .m_axis_tstrb(),
   .m_axis_tuser(),
   .m_axis_tkeep(),

    // Other unused signals
   .almost_empty_axis(),
   .almost_full_axis(),
   .dbiterr_axis(),
   .prog_empty_axis(),
   .prog_full_axis(),
   .rd_data_count_axis(),
   .sbiterr_axis(),
   .wr_data_count_axis(),
   .injectdbiterr_axis(),
   .injectsbiterr_axis()
);
//=============================================================================



//=============================================================================
// This FIFO holds PCI address and number of packet cycles for writing to 
// the AW-channel of M_AXI
//=============================================================================
xpm_fifo_axis #
(
   .FIFO_DEPTH      (16),
   .TDATA_WIDTH     (72),
   .FIFO_MEMORY_TYPE("auto"),
   .PACKET_FIFO     ("false"),
   .USE_ADV_FEATURES("0000"),
   .CLOCKING_MODE   ("common_clock")
)
aw_fifo
(
    // Clock and reset
   .s_aclk   (clk   ),
   .m_aclk   (clk   ),
   .s_aresetn(resetn),

    // The input bus of the FIFO
   .s_axis_tdata ({awlen, pci_address}),
   .s_axis_tvalid(is_header           ),
   .s_axis_tready(                    ),

    // The output bus of the FIFO
   .m_axis_tdata ({M_AXI_AWLEN, M_AXI_AWADDR}),
   .m_axis_tvalid(M_AXI_AWVALID ),
   .m_axis_tready(M_AXI_AWREADY ),

    // Unused input stream signals
   .s_axis_tlast(),
   .s_axis_tkeep(),
   .s_axis_tdest(),
   .s_axis_tid  (),
   .s_axis_tstrb(),
   .s_axis_tuser(),

    // Unused output stream signals
   .m_axis_tlast(),
   .m_axis_tdest(),
   .m_axis_tid  (),
   .m_axis_tstrb(),
   .m_axis_tuser(),
   .m_axis_tkeep(),

    // Other unused signals
   .almost_empty_axis(),
   .almost_full_axis(),
   .dbiterr_axis(),
   .prog_empty_axis(),
   .prog_full_axis(),
   .rd_data_count_axis(),
   .sbiterr_axis(),
   .wr_data_count_axis(),
   .injectdbiterr_axis(),
   .injectsbiterr_axis()
);
//=============================================================================




endmodule