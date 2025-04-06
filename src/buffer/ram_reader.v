//====================================================================================
//                        ------->  Revision History  <------
//====================================================================================
//
//   Date     Who   Ver  Changes
//====================================================================================
// 17-Mar-25  DWW     1  Initial creation
//====================================================================================

/*
    Reads RAM and writes the data to an output stream
*/

module ram_reader # (parameter DW=512, IW=5)
(
    input   clk, resetn,

    // The number of full blocks of data we should read from RAM
    input[31:0] full_blocks,

    // The number of cycles in the optional "partial" block at the
    // end of the full blocks
    input[7:0] partial_block_cycles,

    // When this goes high, the reading begins
    input start,

    // When this is high, all data has been read from RAM
    output idle,

    // The output stream
    output[DW-1:0] AXIS_OUT_TDATA,
    output         AXIS_OUT_TVALID,
    input          AXIS_OUT_TREADY,

    //======================   AXIMM interface to RAM   =======================

    // "Specify write address"              -- Master --    -- Slave --
    output     [63:0]                        M_AXI_AWADDR,
    output     [7:0]                         M_AXI_AWLEN,
    output     [2:0]                         M_AXI_AWSIZE,
    output     [IW-1:0]                      M_AXI_AWID,
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
    output reg [63:0]                       M_AXI_ARADDR,
    output                                  M_AXI_ARVALID,
    output     [2:0]                        M_AXI_ARPROT,
    output                                  M_AXI_ARLOCK,
    output     [IW-1:0]                     M_AXI_ARID,
    output reg [7:0]                        M_AXI_ARLEN,
    output     [2:0]                        M_AXI_ARSIZE,    
    output     [1:0]                        M_AXI_ARBURST,
    output     [3:0]                        M_AXI_ARCACHE,
    output     [3:0]                        M_AXI_ARQOS,
    input                                                   M_AXI_ARREADY,

    // "Read data back to master"           -- Master --    -- Slave --
    input[DW-1:0]                                           M_AXI_RDATA,
    input                                                   M_AXI_RVALID,
    input[1:0]                                              M_AXI_RRESP,
    input                                                   M_AXI_RLAST,
    output                                  M_AXI_RREADY
    //=========================================================================

);

// Include some localparams that define the way we interact with RAM
`include "geometry.vh"

// This is the total number of data-cycles we expected to read
wire[31:0] total_cycles = full_blocks * CYCLES_PER_RAM_BLOCK
                        + partial_block_cycles;

// This is the number of data-cycles we've received from RAM
reg[31:0] cycles_read;

//=============================================================================
// This block counts data cycles as they arrive on the R-channel of M_AXI
//=============================================================================
always @(posedge clk) begin

    if (resetn == 0 || start)
        cycles_read <= 0;

    else if (M_AXI_RVALID & M_AXI_RREADY)
        cycles_read <= cycles_read + 1;

end
//=============================================================================



//=============================================================================
// This block issues read requests and waits for all of the data to arrive
//=============================================================================
reg[ 1:0] fsm_state;
reg[31:0] ar_blocks;

localparam FSM_IDLE          = 0;
localparam FSM_FULL_BLOCKS   = 1;
localparam FSM_PARTIAL_BLOCK = 2;
localparam FSM_WAIT_FOR_DATA = 3;
//-----------------------------------------------------------------------------
always @(posedge clk) begin

    if (resetn == 0) begin
        fsm_state <= FSM_IDLE;
    end

    else case(fsm_state)

        // If we are told to start reading, we will either start
        // reading full blocks or (if there are none) read the
        // partial block at the end
        FSM_IDLE:
            if (start) begin
                M_AXI_ARADDR <= 0;
                if (full_blocks) begin
                    ar_blocks   <= 1;
                    M_AXI_ARLEN <= CYCLES_PER_RAM_BLOCK - 1;
                    fsm_state   <= FSM_FULL_BLOCKS;
                end 

                else if (partial_block_cycles) begin
                    M_AXI_ARLEN <= partial_block_cycles - 1;
                    fsm_state   <= FSM_PARTIAL_BLOCK;
                end
            end


        // If we just issued our last read-request for full blocks
        // we are either done or we need to issue the read-request
        // for the partial-block at the end
        FSM_FULL_BLOCKS:
            if (M_AXI_ARVALID & M_AXI_ARREADY) begin

                M_AXI_ARADDR <= M_AXI_ARADDR + BURST_BYTES;

                if (ar_blocks < full_blocks) begin
                    ar_blocks <= ar_blocks + 1;
                end
              
                else if (partial_block_cycles) begin
                    M_AXI_ARLEN <= partial_block_cycles - 1;
                    fsm_state   <= FSM_PARTIAL_BLOCK;
                end

                else fsm_state <= FSM_WAIT_FOR_DATA;

            end

        // Wait for acceptance of the read-request for the partial block
        FSM_PARTIAL_BLOCK:
            if (M_AXI_ARVALID & M_AXI_ARREADY)
                fsm_state <= FSM_WAIT_FOR_DATA;

        // Here we wait for the data to finish arriving
        FSM_WAIT_FOR_DATA:
            if (cycles_read == total_cycles)
                fsm_state <= FSM_IDLE;

    endcase

end

// ARVALID is high anytime we're waiting for acceptance on the AR channel
assign M_AXI_ARVALID = (fsm_state == FSM_FULL_BLOCKS || fsm_state == FSM_PARTIAL_BLOCK);

// Tell the outside world whether or not we're idle
assign idle = (fsm_state == 0) & (start == 0);
//=============================================================================



//=============================================================================
// Wire the R-channel of M_AXI to the output stream
//=============================================================================
assign AXIS_OUT_TDATA  = M_AXI_RDATA;
assign AXIS_OUT_TVALID = M_AXI_RVALID;
assign M_AXI_RREADY    = AXIS_OUT_TREADY;
//=============================================================================


//=============================================================================
// These are the M_AXI AR-channel values that never change
//=============================================================================
assign M_AXI_ARSIZE  = $clog2(DW/8);
assign M_AXI_ARBURST = 1;
assign M_AXI_ARPROT  = 0;
assign M_AXI_ARLOCK  = 0;
assign M_AXI_ARID    = 0;
assign M_AXI_ARCACHE = 0;
assign M_AXI_ARQOS   = 0;
//=============================================================================



//=============================================================================
// All signals associated with writing to M_AXI are unused
//=============================================================================
assign M_AXI_AWADDR  = 0;
assign M_AXI_AWLEN   = 0;
assign M_AXI_AWSIZE  = 0;
assign M_AXI_AWID    = 0;
assign M_AXI_AWBURST = 0;
assign M_AXI_AWLOCK  = 0;
assign M_AXI_AWCACHE = 0;
assign M_AXI_AWQOS   = 0;
assign M_AXI_AWPROT  = 0;
assign M_AXI_AWVALID = 0;

assign M_AXI_WDATA   = 0;
assign M_AXI_WSTRB   = 0;
assign M_AXI_WVALID  = 0;
assign M_AXI_WLAST   = 0;

assign M_AXI_BREADY  = 0;
//=============================================================================

endmodule
