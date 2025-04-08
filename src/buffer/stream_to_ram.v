//====================================================================================
//                        ------->  Revision History  <------
//====================================================================================
//
//   Date     Who   Ver  Changes
//====================================================================================
// 17-Mar-25  DWW     1  Initial creation
//====================================================================================

/*
     Reads a stream of incoming data and writes it to RAM
*/

//`define DEBUG

module stream_to_ram # (parameter DW=512, IW=4, CHANNEL = 0)
(
    `ifdef DEBUG
        output       dbg_new_inflow,
        output[31:0] dbg_acks_rcvd,
        output[31:0] dbg_total_writes,
    `endif

    input   clk, resetn,

    // If this matches CHANNEL, data is currently flowing in to us.
    input   inflow_q,

    // This will go high if at any point we overflow the RAM 
    output reg overflow,

    // The total number of data-cycles received on the input
    output[31:0] cycles_rcvd,

    // The total number of full blocks in the incoming data
    output[31:0] full_blocks,

    // The number of cycles in the (potential) partial-boock at the end
    output[ 7:0] cycles_in_partial_block,

    // This will go high when we receive our first cycle of input data
    output has_data,
    
    // This goes high when after the final burst of data is written to RAM
    output done,

    // The high-water mark of RAM usage
    output reg[63:0] hwm,

    // Input stream 
    input [DW-1:0] AXIS_IN_TDATA,
    input          AXIS_IN_TVALID,
    output         AXIS_IN_TREADY,

    //=================   This is the AXI4 output interface   ==================

    // "Specify write address"              -- Master --    -- Slave --
    output reg [63:0]                        M_AXI_AWADDR,
    output reg [7:0]                         M_AXI_AWLEN,
    output     [2:0]                         M_AXI_AWSIZE,
    output     [IW-1:0]                      M_AXI_AWID,
    output     [1:0]                         M_AXI_AWBURST,
    output                                   M_AXI_AWLOCK,
    output     [3:0]                         M_AXI_AWCACHE,
    output     [3:0]                         M_AXI_AWQOS,
    output     [2:0]                         M_AXI_AWPROT,
    output reg                               M_AXI_AWVALID,
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
    output[IW-1:0]                          M_AXI_ARID,
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

// Include some constants that define our interactions with RAM
`include "geometry.vh"

// These are the TREADY input and TVALID output of the packet data FIFO
wire fpdout_tready;
wire fpdout_tvalid;

// This will be a '1' on any cycle where a data-transfer is happening in the input stream
wire axis_xfer = (AXIS_IN_TVALID & AXIS_IN_TREADY);


//=============================================================================
// This block asserts "overflow" if we attempt to write off the end of RAM
//=============================================================================
always @(posedge clk) begin
    if (resetn == 0) 
        overflow <= 0;
    else if (M_AXI_AWVALID & M_AXI_AWREADY & (M_AXI_AWADDR >= RAM_SIZE))
        overflow <= 1;
end
//=============================================================================


//=============================================================================
// Keep track of the high-water mark of RAM usage
//=============================================================================
wire[63:0] ram_usage = M_AXI_AWADDR + BURST_BYTES;
//-----------------------------------------------------------------------------
always @(posedge clk) begin
    if (resetn == 0) 
        hwm <= 0;
    else if (M_AXI_AWVALID & M_AXI_AWREADY & (ram_usage > hwm))
        hwm <= ram_usage;
end
//=============================================================================



//=============================================================================
// Keep track of the prior state of inflow_q
//=============================================================================
reg prior_inflow_q;
//-----------------------------------------------------------------------------
always @(posedge clk) begin
    if (resetn == 0)
        prior_inflow_q <= 0;
    else
        prior_inflow_q <= inflow_q;
end
wire new_inflow = (prior_inflow_q != CHANNEL) & (inflow_q == CHANNEL);
//=============================================================================


//=============================================================================
// Keeps track of the number of data-cycles received so far.  Whenever a new
// inflow begins, "cycles_rcvd_reg" becomes either 0 or 1, depending on whether
// there is incoming data on that same clock-cycle
//=============================================================================
reg[31:0] cycles_rcvd_reg;
//-----------------------------------------------------------------------------
always @(posedge clk) begin
    if (resetn == 0)
        cycles_rcvd_reg <= 0;

    else if (new_inflow)
        cycles_rcvd_reg <= axis_xfer;

    else if (AXIS_IN_TREADY & AXIS_IN_TVALID)
        cycles_rcvd_reg <= cycles_rcvd_reg + 1;
end
//=============================================================================

// This is the number of data-cycles received including the one being received
// right now (if there is one)
assign cycles_rcvd = (resetn == 0) ? 0
                   : (new_inflow ) ? axis_xfer
                   : (cycles_rcvd_reg + axis_xfer);

// How many full blocks of data have we received?
assign full_blocks = cycles_rcvd / CYCLES_PER_RAM_BLOCK;

// How many cycles are in the partial block at the end?
assign cycles_in_partial_block = (inflow_q == CHANNEL) ? 0 : cycles_rcvd % CYCLES_PER_RAM_BLOCK;

// This is the total number of bursts that will be written to RAM
wire[31:0] total_writes = full_blocks + (cycles_in_partial_block > 0);

// The number of write requests (for full blocks of data) issued on channel AW
reg[31:0] aw_blocks;

// The number of full blocks of data written to the W-channel of M_AXI
reg[31:0] w_blocks;


//=============================================================================
// This state-machine writes requests to the AW channel of the M_AXI interface. 
// It will issue a write-request any time we receive a full burst's worth of 
// data and for the potential partial-block at the end of the input stream.
//=============================================================================
reg[1:0] awsm_state;
//-----------------------------------------------------------------------------
always @(posedge clk) begin
    
    if (resetn == 0 || new_inflow) begin
        M_AXI_AWADDR  <= 0;
        M_AXI_AWVALID <= 0;
        aw_blocks     <= 0;
        awsm_state    <= 0;
    end

    else case (awsm_state)

        // If we have a full burst's worth of data in the data-FIFO...
    0:  if (full_blocks > aw_blocks) begin
            M_AXI_AWLEN   <= CYCLES_PER_RAM_BLOCK - 1;
            M_AXI_AWVALID <= 1;
            awsm_state    <= 1;
        end

        // Otherwise, if there will be no more data arriving...
        else if (cycles_in_partial_block) begin
            M_AXI_AWLEN   <= cycles_in_partial_block - 1;
            M_AXI_AWVALID <= 1;
            awsm_state    <= 2;
        end
    
    // Here we wait for the request on the AW channel to be received
    1:  if (M_AXI_AWVALID & M_AXI_AWREADY) begin
            M_AXI_AWADDR  <= M_AXI_AWADDR + BURST_BYTES;
            M_AXI_AWVALID <= 0;
            aw_blocks     <= aw_blocks + 1;
            awsm_state    <= 0;
        end

    // Here we wait for the final (partial) block to 
    // be acknowledged, then hang
    2:  if (M_AXI_AWVALID & M_AXI_AWREADY) begin
            M_AXI_AWVALID <= 0;
        end

    endcase

end
//=============================================================================


//=============================================================================
// This state machine writes data from the FIFO to the W-channel 
//=============================================================================
reg[1:0] wsm_state;
reg[7:0] cycles_remaining_in_block;
//-----------------------------------------------------------------------------
always @(posedge clk) begin

    if (resetn == 0 || new_inflow) begin
        wsm_state <= 0;
        w_blocks  <= 0;
    end

    else case (wsm_state)

        0:  if (w_blocks < full_blocks) begin
                cycles_remaining_in_block <= CYCLES_PER_RAM_BLOCK;
                w_blocks                  <= w_blocks + 1;
                wsm_state                 <= 1;
            end

            else if (cycles_in_partial_block) begin
                cycles_remaining_in_block <= cycles_in_partial_block;
                wsm_state                 <= 2;
            end

        // Output bursts of data until w_blocks = full_blocks        
        1:  if (M_AXI_WVALID & M_AXI_WREADY) begin

                cycles_remaining_in_block <= cycles_remaining_in_block - 1;

                if (M_AXI_WLAST) begin
                    if (w_blocks == full_blocks)
                        wsm_state <= 0;
                    else begin
                        cycles_remaining_in_block <= CYCLES_PER_RAM_BLOCK;
                        w_blocks                  <= w_blocks + 1;
                    end
                end

            end

        // Wait for the last partial-block of data to be written
        2:  if (M_AXI_WVALID & M_AXI_WREADY) begin
                if (M_AXI_WLAST) begin
                    wsm_state <= 3;
                end

                cycles_remaining_in_block <= cycles_remaining_in_block - 1;
            end

        // Here, we're just waiting for either reset or new_inflow_q
        3:  wsm_state <= wsm_state;

    endcase
end
//=============================================================================

// The WLAST signal is high only on the last data-cycle of a burst
assign M_AXI_WLAST = (cycles_remaining_in_block == 1);

// The WVALID signal is high only when data is available from the FIFO
assign M_AXI_WVALID = (wsm_state == 1 || wsm_state == 2) & fpdout_tvalid;

// The TREADY signal to the FIFO is high when the incoming WREADY signal is high
assign fpdout_tready = (wsm_state == 1 || wsm_state == 2) & M_AXI_WREADY;

//=============================================================================
// This state machine counts the number of write-acknowledgents that we receive
// from RAM
//=============================================================================
reg[31:0] acks_rcvd;
//-----------------------------------------------------------------------------
always @(posedge clk) begin

    if (resetn == 0 || new_inflow)
        acks_rcvd <= 0;

    else if (M_AXI_BREADY & M_AXI_BVALID)
        acks_rcvd <= acks_rcvd + 1;

end
//=============================================================================

// This will be high once we've received the B-channel acknowledgement for 
// the last burst of data we wrote to RAM
assign done = (inflow_q != CHANNEL) & (acks_rcvd == total_writes); 

// The "has_data" line goes high the moment we receive the first cycle of data
assign has_data = (cycles_rcvd != 0);

//=============================================================================
// Constant values for the AW-channel of the M_AXI interface
//=============================================================================
assign M_AXI_AWSIZE  = $clog2(DW/8);
assign M_AXI_AWID    = 0;
assign M_AXI_AWBURST = 1;
assign M_AXI_AWLOCK  = 0;
assign M_AXI_AWCACHE = 0;
assign M_AXI_AWQOS   = 0;
assign M_AXI_AWPROT  = 0;
//=============================================================================    

//=============================================================================
// Constant values for the W-channel of the M_AXI interface
//=============================================================================
assign M_AXI_WSTRB = -1;
//=============================================================================

//=============================================================================
// Constant values for the B-channel of the M_AXI interface
//=============================================================================
assign M_AXI_BREADY = (resetn != 0);
//=============================================================================

//=============================================================================
// This FIFO holds incoming packet-data
//=============================================================================
xpm_fifo_axis #
(
   .FIFO_DEPTH      (4 * CYCLES_PER_RAM_BLOCK),
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
   .s_axis_tvalid(AXIS_IN_TVALID),
   .s_axis_tready(AXIS_IN_TREADY),

    // The output bus of the FIFO
   .m_axis_tdata (M_AXI_WDATA  ),
   .m_axis_tvalid(fpdout_tvalid),
   .m_axis_tready(fpdout_tready),

    // Unused input stream signals
   .s_axis_tkeep(),
   .s_axis_tlast(),
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


//=============================================================================
// Output fields for debugging
//=============================================================================
`ifdef DEBUG
    assign dbg_new_inflow   = new_inflow;
    assign dbg_acks_rcvd    = acks_rcvd;
    assign dbg_total_writes = total_writes;
`endif
//=============================================================================



endmodule
