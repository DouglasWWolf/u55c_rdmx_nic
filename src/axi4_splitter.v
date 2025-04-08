
//====================================================================================
//                        ------->  Revision History  <------
//====================================================================================
//
//   Date     Who   Ver  Changes
//====================================================================================
// 02-Apr-25  DWW     1  Initial creation
//====================================================================================

/*
    This splits an AXI4 master interface into two AXI4 master interfaces that are
    half as wide as the input.

    This module assumes the the WSTRB signal always indicates that all bytes of WDATA
    are valid.

    The original intended use of this module is to split a 512-bit AXI4 interface 
    into a pair of 256-bit AXI interfaces.  (The AXI interfaces on Xilinx HBM are
    all 256 bits wide).
*/

module axi4_splitter #
(
    parameter DW=512,
    parameter AW=64,
    parameter IW=5,
    parameter OAW=34,
    parameter ENABLE_WRITE = 1,
    parameter ENABLE_READ  = 1,
    parameter AW_FIFO_DEPTH = 16,
    parameter AR_FIFO_DEPTH = 16,
    parameter  W_FIFO_DEPTH = 256,
    parameter  R_FIFO_DEPTH = 256,
    parameter[63:0] BASE_ADDR0 = 64'h0, BASE_ADDR1 = 64'h0
)
(

    input clk, resetn,


    //==================  This is an AXI4-slave interface  =====================

    // "Specify write address"              -- Master --    -- Slave --
    input     [AW-1:0]                      S_AXI_AWADDR,
    input                                   S_AXI_AWVALID,
    input     [7:0]                         S_AXI_AWLEN,
    input     [2:0]                         S_AXI_AWSIZE,
    input     [IW-1:0]                      S_AXI_AWID,
    input     [1:0]                         S_AXI_AWBURST,
    input                                   S_AXI_AWLOCK,
    input     [3:0]                         S_AXI_AWCACHE,
    input     [3:0]                         S_AXI_AWQOS,
    input     [2:0]                         S_AXI_AWPROT,
    output                                                  S_AXI_AWREADY,

    // "Write Data"                         -- Master --    -- Slave --
    input     [DW-1:0]                      S_AXI_WDATA,
    input     [(DW/8)-1:0]                  S_AXI_WSTRB,
    input                                   S_AXI_WVALID,
    input                                   S_AXI_WLAST,
    output                                                  S_AXI_WREADY,

    // "Send Write Response"                -- Master --    -- Slave --
    output[1:0]                                             S_AXI_BRESP,
    output                                                  S_AXI_BVALID,
    input                                   S_AXI_BREADY,

    // "Specify read address"               -- Master --    -- Slave --
    input     [AW-1:0]                      S_AXI_ARADDR,
    input                                   S_AXI_ARVALID,
    input     [2:0]                         S_AXI_ARPROT,
    input                                   S_AXI_ARLOCK,
    input     [IW-1:0]                      S_AXI_ARID,
    input     [2:0]                         S_AXI_ARSIZE,
    input     [7:0]                         S_AXI_ARLEN,
    input     [1:0]                         S_AXI_ARBURST,
    input     [3:0]                         S_AXI_ARCACHE,
    input     [3:0]                         S_AXI_ARQOS,
    output                                                  S_AXI_ARREADY,

    // "Read data back to master"           -- Master --    -- Slave --
    output[DW-1:0]                                          S_AXI_RDATA,
    output                                                  S_AXI_RVALID,
    output[1:0]                                             S_AXI_RRESP,
    output                                                  S_AXI_RLAST,
    input                                   S_AXI_RREADY,
    //==========================================================================


    //==================  This is an AXI4-master interface  ===================

    // "Specify write address"              -- Master --    -- Slave --
    output     [OAW-1:0]                    M0_AXI_AWADDR,
    output                                  M0_AXI_AWVALID,
    output     [7:0]                        M0_AXI_AWLEN,
    output     [2:0]                        M0_AXI_AWSIZE,
    output     [IW-1:0]                     M0_AXI_AWID,
    output     [1:0]                        M0_AXI_AWBURST,
    output                                  M0_AXI_AWLOCK,
    output     [3:0]                        M0_AXI_AWCACHE,
    output     [3:0]                        M0_AXI_AWQOS,
    output     [2:0]                        M0_AXI_AWPROT,
    input                                                   M0_AXI_AWREADY,

    // "Write Data"                         -- Master --    -- Slave --
    output     [DW/2-1:0]                   M0_AXI_WDATA,
    output     [(DW/16)-1:0]                M0_AXI_WSTRB,
    output                                  M0_AXI_WVALID,
    output                                  M0_AXI_WLAST,
    input                                                   M0_AXI_WREADY,

    // "Send Write Response"                -- Master --    -- Slave --
    input[1:0]                                              M0_AXI_BRESP,
    input                                                   M0_AXI_BVALID,
    output                                  M0_AXI_BREADY,

    // "Specify read address"               -- Master --    -- Slave --
    output     [OAW-1:0]                    M0_AXI_ARADDR,
    output                                  M0_AXI_ARVALID,
    output     [2:0]                        M0_AXI_ARPROT,
    output                                  M0_AXI_ARLOCK,
    output     [IW-1:0]                     M0_AXI_ARID,
    output     [2:0]                        M0_AXI_ARSIZE,
    output     [7:0]                        M0_AXI_ARLEN,
    output     [1:0]                        M0_AXI_ARBURST,
    output     [3:0]                        M0_AXI_ARCACHE,
    output     [3:0]                        M0_AXI_ARQOS,
    input                                                   M0_AXI_ARREADY,

    // "Read data back to master"           -- Master --    -- Slave --
    input[DW/2-1:0]                                         M0_AXI_RDATA,
    input                                                   M0_AXI_RVALID,
    input[1:0]                                              M0_AXI_RRESP,
    input                                                   M0_AXI_RLAST,
    output                                  M0_AXI_RREADY,
    //==========================================================================



    //==================  This is an AXI4-master interface  ===================

    // "Specify write address"              -- Master --    -- Slave --
    output     [OAW-1:0]                    M1_AXI_AWADDR,
    output                                  M1_AXI_AWVALID,
    output     [7:0]                        M1_AXI_AWLEN,
    output     [2:0]                        M1_AXI_AWSIZE,
    output     [IW-1:0]                     M1_AXI_AWID,
    output     [1:0]                        M1_AXI_AWBURST,
    output                                  M1_AXI_AWLOCK,
    output     [3:0]                        M1_AXI_AWCACHE,
    output     [3:0]                        M1_AXI_AWQOS,
    output     [2:0]                        M1_AXI_AWPROT,
    input                                                   M1_AXI_AWREADY,

    // "Write Data"                         -- Master --    -- Slave --
    output     [DW/2-1:0]                   M1_AXI_WDATA,
    output     [(DW/16)-1:0]                M1_AXI_WSTRB,
    output                                  M1_AXI_WVALID,
    output                                  M1_AXI_WLAST,
    input                                                   M1_AXI_WREADY,

    // "Send Write Response"                -- Master --    -- Slave --
    input[1:0]                                              M1_AXI_BRESP,
    input                                                   M1_AXI_BVALID,
    output                                  M1_AXI_BREADY,

    // "Specify read address"               -- Master --    -- Slave --
    output     [OAW-1:0]                    M1_AXI_ARADDR,
    output                                  M1_AXI_ARVALID,
    output     [2:0]                        M1_AXI_ARPROT,
    output                                  M1_AXI_ARLOCK,
    output     [IW-1:0]                     M1_AXI_ARID,
    output     [2:0]                        M1_AXI_ARSIZE,
    output     [7:0]                        M1_AXI_ARLEN,
    output     [1:0]                        M1_AXI_ARBURST,
    output     [3:0]                        M1_AXI_ARCACHE,
    output     [3:0]                        M1_AXI_ARQOS,
    input                                                   M1_AXI_ARREADY,

    // "Read data back to master"           -- Master --    -- Slave --
    input[DW/2-1:0]                                         M1_AXI_RDATA,
    input                                                   M1_AXI_RVALID,
    input[1:0]                                              M1_AXI_RRESP,
    input                                                   M1_AXI_RLAST,
    output                                  M1_AXI_RREADY
    //==========================================================================

);

genvar i;

// Handy constant that has both bits on
localparam[1:0] BOTH = 2'b11;

// The number of whole bytes required to store "OAW" bits
localparam OAW_BYTES = (OAW/8) + (OAW%8 != 0);

// The number of bits reqired to store {AxARADDR, AxLEN}
localparam AxFIFO_WIDTH = (OAW_BYTES + 1) * 8;

// These are driven by the input side of the FIFOs
wire[1:0] wfifo_in_tready, awfifo_in_tready, arfifo_in_tready;

// A valid signal won't assert until both of the FIFOs it drives are ready
wire arfifo_in_tvalid = S_AXI_ARVALID & (arfifo_in_tready == BOTH);
wire awfifo_in_tvalid = S_AXI_AWVALID & (awfifo_in_tready == BOTH);
wire  wfifo_in_tvalid = S_AXI_WVALID  & ( wfifo_in_tready == BOTH);

// The slave side AW, AR, and W channels are ready when both of their fifos are ready
assign S_AXI_ARREADY = ENABLE_READ  & (resetn == 1) & (arfifo_in_tready == BOTH);
assign S_AXI_AWREADY = ENABLE_WRITE & (resetn == 1) & (awfifo_in_tready == BOTH);
assign S_AXI_WREADY  = ENABLE_WRITE & (resetn == 1) & ( wfifo_in_tready == BOTH);

// These are the AXI addresses that go into the AW and R fifos
wire[OAW_BYTES*8-1:0] awaddr[0:1], araddr[0:1];
assign awaddr[0] = (S_AXI_AWADDR / 2) + BASE_ADDR0;
assign awaddr[1] = (S_AXI_AWADDR / 2) + BASE_ADDR1;
assign araddr[0] = (S_AXI_ARADDR / 2) + BASE_ADDR0;
assign araddr[1] = (S_AXI_ARADDR / 2) + BASE_ADDR1;

// These "credit counters" are incremented every time a B-channel acknowledgement
// happens on one of the M_AXI interfaces, and are decrememented every time a
// B-channel acknowledgement happens on the S_AXI interface
reg[31:0] b_credits[0:1]; 

// Output a B-channel ack on S_AXI whenever both M_AXI have outstanding credits
assign S_AXI_BVALID = (resetn == 1) && b_credits[0] > 0 && b_credits[1] > 0;

// The slave-side B-acknowledgement is always "OKAY"
assign S_AXI_BRESP = 0;

// Driven by the output side of r_fifo_0 and r_fifo_1
wire[1:0] rfifo_out_tvalid;

// S_AXI_RVALID is valid only when the outputs of both of its FIFOs are valid
assign S_AXI_RVALID = ENABLE_READ & (resetn == 1) & (rfifo_out_tvalid == BOTH);

// Advance the R-channel FIFOs when both FIFOs are valid and S_AXI shows ready
wire rfifo_out_tready = S_AXI_RVALID & S_AXI_RREADY;

//=============================================================================
// Constant outputs for the AW channel
//=============================================================================
assign M0_AXI_AWSIZE  = $clog2(DW/16);   
assign M0_AXI_AWID    = S_AXI_AWID;   
assign M0_AXI_AWBURST = S_AXI_AWBURST;
assign M0_AXI_AWLOCK  = S_AXI_AWLOCK;
assign M0_AXI_AWCACHE = S_AXI_AWCACHE;
assign M0_AXI_AWQOS   = S_AXI_AWQOS;
assign M0_AXI_AWPROT  = S_AXI_AWPROT;
if (ENABLE_WRITE == 0) begin
    assign M0_AXI_AWADDR = 0;
    assign M0_AXI_AWLEN  = 0;
    assign M0_AXI_AWVALID = 0;
end


assign M1_AXI_AWSIZE  = $clog2(DW/16);   
assign M1_AXI_AWID    = S_AXI_AWID;   
assign M1_AXI_AWBURST = S_AXI_AWBURST;
assign M1_AXI_AWLOCK  = S_AXI_AWLOCK;
assign M1_AXI_AWCACHE = S_AXI_AWCACHE;
assign M1_AXI_AWQOS   = S_AXI_AWQOS;
assign M1_AXI_AWPROT  = S_AXI_AWPROT;
if (ENABLE_WRITE == 0) begin
    assign M1_AXI_AWADDR = 0;
    assign M1_AXI_AWLEN  = 0;
    assign M1_AXI_AWVALID = 0;
end
//=============================================================================


//=============================================================================
// Constant outputs for the B channel
//=============================================================================
assign M0_AXI_BREADY = S_AXI_BREADY & (resetn == 1) & ENABLE_WRITE;
assign M1_AXI_BREADY = S_AXI_BREADY & (resetn == 1) & ENABLE_WRITE;
//=============================================================================


//=============================================================================
// Constant outputs for the W channel
//=============================================================================
assign M0_AXI_WSTRB = -1;
assign M1_AXI_WSTRB = -1;
//=============================================================================


//=============================================================================
// This block ensures that a B-channel acknowledge happens on S_AXI for every
// B-channel ackowledgement on both of the M_AXI channels
//=============================================================================
wire[1:0] add_credit;
assign    add_credit[0] = M0_AXI_BREADY & M0_AXI_BVALID;
assign    add_credit[1] = M1_AXI_BREADY & M1_AXI_BVALID;
wire      sub_credit    = S_AXI_BREADY  & S_AXI_BVALID;
//-----------------------------------------------------------------------------
for (i=0; i<2; i=i+1) begin
    always @(posedge clk) begin
        if (resetn == 0)
            b_credits[i] <= 0;
        else if (add_credit[i] == 1 && sub_credit == 0)
            b_credits[i] <= b_credits[i] + 1;
        else if (add_credit[i] == 0 && sub_credit == 1)
            b_credits[i] <= b_credits[i] - 1;    
    end
end
//=============================================================================


//=============================================================================
// Constant outputs for the AW channel
//=============================================================================
assign M0_AXI_ARSIZE  = $clog2(DW/16);   
assign M0_AXI_ARID    = S_AXI_ARID;   
assign M0_AXI_ARBURST = S_AXI_ARBURST;
assign M0_AXI_ARLOCK  = S_AXI_ARLOCK;
assign M0_AXI_ARCACHE = S_AXI_ARCACHE;
assign M0_AXI_ARQOS   = S_AXI_ARQOS;
assign M0_AXI_ARPROT  = S_AXI_ARPROT;
if (ENABLE_READ == 0) begin
    assign M0_AXI_ARADDR = 0;
    assign M0_AXI_ARLEN  = 0;
    assign M0_AXI_ARVALID = 0;
end


assign M1_AXI_ARSIZE  = $clog2(DW/16);   
assign M1_AXI_ARID    = S_AXI_ARID;   
assign M1_AXI_ARBURST = S_AXI_ARBURST;
assign M1_AXI_ARLOCK  = S_AXI_ARLOCK;
assign M1_AXI_ARCACHE = S_AXI_ARCACHE;
assign M1_AXI_ARQOS   = S_AXI_ARQOS;
assign M1_AXI_ARPROT  = S_AXI_ARPROT;
if (ENABLE_READ == 0) begin
    assign M1_AXI_ARADDR = 0;
    assign M1_AXI_ARLEN  = 0;
    assign M1_AXI_ARVALID = 0;
end
//=============================================================================




//=============================================================================
// This FIFO holds incoming AW-channel data
//=============================================================================
if (ENABLE_WRITE) begin
xpm_fifo_axis #
(
   .FIFO_DEPTH      (AW_FIFO_DEPTH),
   .TDATA_WIDTH     (AxFIFO_WIDTH),
   .FIFO_MEMORY_TYPE("auto"),
   .PACKET_FIFO     ("false"),
   .USE_ADV_FEATURES("0000"),
   .CLOCKING_MODE   ("common_clock")
)
aw_fifo_0
(
    // Clock and reset
   .s_aclk   (clk   ),
   .m_aclk   (clk   ),
   .s_aresetn(resetn),

    // The input bus to the FIFO
   .s_axis_tdata ({awaddr[0], S_AXI_AWLEN}),
   .s_axis_tvalid(awfifo_in_tvalid        ),
   .s_axis_tready(awfifo_in_tready[0]     ),

    // The output bus of the FIFO
   .m_axis_tdata ({M0_AXI_AWADDR, M0_AXI_AWLEN}),
   .m_axis_tvalid( M0_AXI_AWVALID              ),
   .m_axis_tready( M0_AXI_AWREADY              ),

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
end
//=============================================================================



//=============================================================================
// This FIFO holds incoming AW-channel data
//=============================================================================
if (ENABLE_WRITE) begin
xpm_fifo_axis #
(
   .FIFO_DEPTH      (AW_FIFO_DEPTH),
   .TDATA_WIDTH     (AxFIFO_WIDTH),
   .FIFO_MEMORY_TYPE("auto"),
   .PACKET_FIFO     ("false"),
   .USE_ADV_FEATURES("0000"),
   .CLOCKING_MODE   ("common_clock")
)
aw_fifo_1
(
    // Clock and reset
   .s_aclk   (clk   ),
   .m_aclk   (clk   ),
   .s_aresetn(resetn),

    // The input bus to the FIFO
   .s_axis_tdata ({awaddr[1], S_AXI_AWLEN}),
   .s_axis_tvalid(awfifo_in_tvalid        ),
   .s_axis_tready(awfifo_in_tready[1]     ),

    // The output bus of the FIFO
   .m_axis_tdata ({M1_AXI_AWADDR, M1_AXI_AWLEN}),
   .m_axis_tvalid( M1_AXI_AWVALID             ),
   .m_axis_tready( M1_AXI_AWREADY             ),

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
end
//=============================================================================




//=============================================================================
// This FIFO holds incoming W-channel data
//=============================================================================
if (ENABLE_WRITE) begin
xpm_fifo_axis #
(
   .FIFO_DEPTH      (W_FIFO_DEPTH),
   .TDATA_WIDTH     (DW/2),
   .FIFO_MEMORY_TYPE("auto"),
   .PACKET_FIFO     ("false"),
   .USE_ADV_FEATURES("0000"),
   .CLOCKING_MODE   ("common_clock")
)
w_fifo_0
(
    // Clock and reset
   .s_aclk   (clk   ),
   .m_aclk   (clk   ),
   .s_aresetn(resetn),

    // The input bus to the FIFO
   .s_axis_tdata (S_AXI_WDATA[0 +: (DW/2)]),
   .s_axis_tlast (S_AXI_WLAST             ),
   .s_axis_tvalid(wfifo_in_tvalid         ),
   .s_axis_tready(wfifo_in_tready[0]      ),

    // The output bus of the FIFO
   .m_axis_tdata (M0_AXI_WDATA ),
   .m_axis_tlast (M0_AXI_WLAST ),
   .m_axis_tvalid(M0_AXI_WVALID),
   .m_axis_tready(M0_AXI_WREADY),

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
end
//=============================================================================


//=============================================================================
// This FIFO holds incoming W-channel data
//=============================================================================
if (ENABLE_WRITE) begin
xpm_fifo_axis #
(
   .FIFO_DEPTH      (W_FIFO_DEPTH),
   .TDATA_WIDTH     (DW/2),
   .FIFO_MEMORY_TYPE("auto"),
   .PACKET_FIFO     ("false"),
   .USE_ADV_FEATURES("0000"),
   .CLOCKING_MODE   ("common_clock")
)
w_fifo_1
(
    // Clock and reset
   .s_aclk   (clk   ),
   .m_aclk   (clk   ),
   .s_aresetn(resetn),

    // The input bus to the FIFO
   .s_axis_tdata (S_AXI_WDATA[(DW/2) +: (DW/2)]),
   .s_axis_tlast (S_AXI_WLAST                  ),
   .s_axis_tvalid(wfifo_in_tvalid              ),
   .s_axis_tready(wfifo_in_tready[1]           ),

    // The output bus of the FIFO
   .m_axis_tdata (M1_AXI_WDATA ),
   .m_axis_tlast (M1_AXI_WLAST ),
   .m_axis_tvalid(M1_AXI_WVALID),
   .m_axis_tready(M1_AXI_WREADY),

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
end
//=============================================================================


//=============================================================================
// This FIFO holds incoming AR-channel data
//=============================================================================
if (ENABLE_READ) begin
xpm_fifo_axis #
(
   .FIFO_DEPTH      (AR_FIFO_DEPTH),
   .TDATA_WIDTH     (AxFIFO_WIDTH),
   .FIFO_MEMORY_TYPE("auto"),
   .PACKET_FIFO     ("false"),
   .USE_ADV_FEATURES("0000"),
   .CLOCKING_MODE   ("common_clock")
)
ar_fifo_0
(
    // Clock and reset
   .s_aclk   (clk   ),
   .m_aclk   (clk   ),
   .s_aresetn(resetn),

    // The input bus to the FIFO
   .s_axis_tdata ({araddr[0], S_AXI_ARLEN}),
   .s_axis_tvalid(arfifo_in_tvalid        ),
   .s_axis_tready(arfifo_in_tready[0]     ),

    // The output bus of the FIFO
   .m_axis_tdata ({M0_AXI_ARADDR, M0_AXI_ARLEN}),
   .m_axis_tvalid( M0_AXI_ARVALID              ),
   .m_axis_tready( M0_AXI_ARREADY              ),

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
end
//=============================================================================


//=============================================================================
// This FIFO holds incoming AR-channel data
//=============================================================================
if (ENABLE_READ) begin
xpm_fifo_axis #
(
   .FIFO_DEPTH      (AR_FIFO_DEPTH),
   .TDATA_WIDTH     (AxFIFO_WIDTH),
   .FIFO_MEMORY_TYPE("auto"),
   .PACKET_FIFO     ("false"),
   .USE_ADV_FEATURES("0000"),
   .CLOCKING_MODE   ("common_clock")
)
ar_fifo_1
(
    // Clock and reset
   .s_aclk   (clk   ),
   .m_aclk   (clk   ),
   .s_aresetn(resetn),

    // The input bus to the FIFO
   .s_axis_tdata ({araddr[1], S_AXI_ARLEN}),
   .s_axis_tvalid(arfifo_in_tvalid        ),
   .s_axis_tready(arfifo_in_tready[1]     ),

    // The output bus of the FIFO
   .m_axis_tdata ({M1_AXI_ARADDR, M1_AXI_ARLEN}),
   .m_axis_tvalid( M1_AXI_ARVALID              ),
   .m_axis_tready( M1_AXI_ARREADY              ),

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
end
//=============================================================================

//=============================================================================
// This FIFO holds incoming R-channel data
//=============================================================================
if (ENABLE_READ) begin
xpm_fifo_axis #
(
   .FIFO_DEPTH      (R_FIFO_DEPTH),
   .TDATA_WIDTH     (DW/2),
   .FIFO_MEMORY_TYPE("auto"),
   .PACKET_FIFO     ("false"),
   .USE_ADV_FEATURES("0000"),
   .CLOCKING_MODE   ("common_clock")
)
r_fifo_0
(
    // Clock and reset
   .s_aclk   (clk   ),
   .m_aclk   (clk   ),
   .s_aresetn(resetn),

    // The input bus to the FIFO
   .s_axis_tdata (M0_AXI_RDATA),
   .s_axis_tlast (M0_AXI_RLAST),
   .s_axis_tvalid(M0_AXI_RVALID),
   .s_axis_tready(M0_AXI_RREADY),

    // The output bus of the FIFO
   .m_axis_tdata (S_AXI_RDATA[0 +: (DW/2)]),
   .m_axis_tlast (S_AXI_RLAST             ),
   .m_axis_tvalid(rfifo_out_tvalid[0]     ),
   .m_axis_tready(rfifo_out_tready        ),

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
end
//=============================================================================



//=============================================================================
// This FIFO holds incoming R-channel data
//=============================================================================
if (ENABLE_READ) begin
xpm_fifo_axis #
(
   .FIFO_DEPTH      (R_FIFO_DEPTH),
   .TDATA_WIDTH     (DW/2),
   .FIFO_MEMORY_TYPE("auto"),
   .PACKET_FIFO     ("false"),
   .USE_ADV_FEATURES("0000"),
   .CLOCKING_MODE   ("common_clock")
)
r_fifo_1
(
    // Clock and reset
   .s_aclk   (clk   ),
   .m_aclk   (clk   ),
   .s_aresetn(resetn),

    // The input bus to the FIFO
   .s_axis_tdata (M1_AXI_RDATA),
   .s_axis_tlast (M1_AXI_RLAST),
   .s_axis_tvalid(M1_AXI_RVALID),
   .s_axis_tready(M1_AXI_RREADY),

    // The output bus of the FIFO
   .m_axis_tdata (S_AXI_RDATA[(DW/2) +: (DW/2)]),
   .m_axis_tlast (                             ),
   .m_axis_tvalid(rfifo_out_tvalid[1]          ),
   .m_axis_tready(rfifo_out_tready             ),

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
end
//=============================================================================




endmodule