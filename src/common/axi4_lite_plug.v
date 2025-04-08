//====================================================================================
//                        ------->  Revision History  <------
//====================================================================================
//
//   Date     Who   Ver  Changes
//====================================================================================
// 02-Mar-24  DWW     1  Initial creation
//====================================================================================

/*
    This is just a "plug" for an empty AXI4-Lite slave port, to keep Vivado
    happy.   This module does nothing at all, simply ensures that an otherwise
    unused AXI4-Lite slave port doesn't cause Vivado to whine.
*/


module axi4_lite_plug # (parameter DW=32, parameter AW=32)
(
    input clk,

    //====================  An AXI-Lite Master Interface  ======================

    // "Specify write address"          -- Master --    -- Slave --
    output [AW-1:0]                     AXI_AWADDR,
    output reg                          AXI_AWVALID,
    output    [2:0]                     AXI_AWPROT,
    input                                               AXI_AWREADY,

    // "Write Data"                     -- Master --    -- Slave --
    output [DW-1:0]                     AXI_WDATA,
    output reg                          AXI_WVALID,
    output [(DW/8)-1:0]                 AXI_WSTRB,
    input                                               AXI_WREADY,

    // "Send Write Response"            -- Master --    -- Slave --
    input      [1:0]                                    AXI_BRESP,
    input                                               AXI_BVALID,
    output reg                          AXI_BREADY,

    // "Specify read address"           -- Master --    -- Slave --
    output [AW-1:0]                     AXI_ARADDR,
    output reg                          AXI_ARVALID,
    output    [2:0]                     AXI_ARPROT,
    input                                               AXI_ARREADY,

    // "Read data back to master"       -- Master --    -- Slave --
    input [DW-1:0]                                      AXI_RDATA,
    input                                               AXI_RVALID,
    input    [1:0]                                      AXI_RRESP,
    output reg                          AXI_RREADY
    //==========================================================================
);

always @(posedge clk) begin
    AXI_AWVALID <= 0;
    AXI_WVALID  <= 0;
    AXI_ARVALID <= 0;
    AXI_BREADY  <= 1;
    AXI_RREADY  <= 1;
end


endmodule