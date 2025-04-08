//====================================================================================
//                        ------->  Revision History  <------
//====================================================================================
//
//   Date     Who   Ver  Changes
//====================================================================================
// 17-Mar-25  DWW     1  Initial creation
//====================================================================================

// This most effecient burst size for writing to RAM is 4KB
localparam BURST_BYTES = 32'h1000;

// The number of clock-cycles in a full burst.  If DW=512, this is 64
localparam CYCLES_PER_RAM_BLOCK = BURST_BYTES / (DW/8);

// Size of each RAM bank, in bytes
localparam[63:0] RAM_SIZE = 64'h1_0000_0000;
