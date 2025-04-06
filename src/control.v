//====================================================================================
//                        ------->  Revision History  <------
//====================================================================================
//
//   Date     Who   Ver  Changes
//====================================================================================
// 17-Mar-25  DWW     1  Initial creation
//====================================================================================

/*
    This provides status and control registers for the rdmx_nic design
*/


module control # (parameter AW=8)
(

    (* X_INTERFACE_PARAMETER = "ASSOCIATED_RESET resetn:resetn_out" *)
    input clk,
    
    input resetn,

    output reg[63:0] packet_count,
    output reg       gen_packets,
    input            generator_idle,

    // While this is 1, the data-flow to the PCI bridge will be suspended
    output pause_pci,

    // These strobe high for one cycle upon the receipt of a good or bad packet
    input bad_packet_strb, good_packet_strb,

    // These indicates that "stream_to_ram" overflowed the available RAM
    input overflow_0, overflow_1,

    // These indicate that the DDR banks passed initial calibration
    input async_ddr_cal_0, async_ddr_cal_1,

    // This is a '1' if the QSFP port has acheived PCS alignment with the peer
    input async_pcs_aligned,

    // Strobes high if we receive a packet with an invalid RDMX target address
    input pci_range_err_strb,

    // We use this to reset the rest of the system
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 resetn_out RST" *)
    output reg resetn_out,

    // When this is a '1', input packets are routed back out the QSFP port
    output reg loopback,

    // These are the high-water mark of RAM usage for each RAM bank
    input[63:0] hwm_0, hwm_1,

    // The base address and size of the contiguous buffer in host RAM
    output reg[63:0] pci_base, pci_size,

    // Control and status for transmitting data out the QSFP
    output reg[63:0] xmit_src_addr,
    output reg[63:0] xmit_dst_addr,
    output reg[63:0] xmit_byte_count,
    output reg       xmit_start,
    input            xmit_idle,

    // We use this to monitor the output of the buffer for sequence errors
    (* X_INTERFACE_MODE = "monitor" *)
    input[511:0] seq_axis_tdata,
    input        seq_axis_tvalid,
    input        seq_axis_tlast,
    input        seq_axis_tready,

    //================== This is an AXI4-Lite slave interface ==================
        
    // "Specify write address"              -- Master --    -- Slave --
    input[AW-1:0]                           S_AXI_AWADDR,   
    input                                   S_AXI_AWVALID,  
    output                                                  S_AXI_AWREADY,
    input[2:0]                              S_AXI_AWPROT,

    // "Write Data"                         -- Master --    -- Slave --
    input[31:0]                             S_AXI_WDATA,      
    input                                   S_AXI_WVALID,
    input[3:0]                              S_AXI_WSTRB,
    output                                                  S_AXI_WREADY,

    // "Send Write Response"                -- Master --    -- Slave --
    output[1:0]                                             S_AXI_BRESP,
    output                                                  S_AXI_BVALID,
    input                                   S_AXI_BREADY,

    // "Specify read address"               -- Master --    -- Slave --
    input[AW-1:0]                           S_AXI_ARADDR,     
    input                                   S_AXI_ARVALID,
    input[2:0]                              S_AXI_ARPROT,     
    output                                                  S_AXI_ARREADY,

    // "Read data back to master"           -- Master --    -- Slave --
    output[31:0]                                            S_AXI_RDATA,
    output                                                  S_AXI_RVALID,
    output[1:0]                                             S_AXI_RRESP,
    input                                   S_AXI_RREADY
    //==========================================================================
);  


//=========================  AXI Register Map  =============================
localparam REG_STATUS         =  0;
localparam REG_ERRORS         =  1;
localparam REG_GOOD_PACKETS_H =  2;
localparam REG_GOOD_PACKETS_L =  3;
localparam REG_BAD_PACKETS_H  =  4;
localparam REG_BAD_PACKETS_L  =  5;
localparam REG_PCI_BASE_H     =  6;
localparam REG_PCI_BASE_L     =  7;
localparam REG_PCI_SIZE_H     =  8;
localparam REG_PCI_SIZE_L     =  9;
localparam REG_RESET          = 10;
localparam REG_CLEAR_COUNTERS = 11;

localparam REG_XMIT_SRCADDR_H = 20;
localparam REG_XMIT_SRCADDR_L = 21;
localparam REG_XMIT_DSTADDR_H = 22;
localparam REG_XMIT_DSTADDR_L = 23;
localparam REG_XMIT_SIZE_H    = 24;
localparam REG_XMIT_SIZE_L    = 25;
localparam REG_XMIT_START     = 26;    

localparam REG_PACKET_COUNT_H = 32;
localparam REG_PACKET_COUNT_L = 33;
localparam REG_LOOPBACK       = 34;
localparam REG_PAUSE_PCI      = 35;
localparam REG_HWMARK_0H      = 36;
localparam REG_HWMARK_0L      = 37;
localparam REG_HWMARK_1H      = 38;
localparam REG_HWMARK_1L      = 39;
//==========================================================================


//==========================================================================
// We'll communicate with the AXI4-Lite Slave core with these signals.
//==========================================================================
// AXI Slave Handler Interface for write requests
wire[31:0]  ashi_windx;     // Input   Write register-index
wire[31:0]  ashi_waddr;     // Input:  Write-address
wire[31:0]  ashi_wdata;     // Input:  Write-data
wire        ashi_write;     // Input:  1 = Handle a write request
reg[1:0]    ashi_wresp;     // Output: Write-response (OKAY, DECERR, SLVERR)
wire        ashi_widle;     // Output: 1 = Write state machine is idle

// AXI Slave Handler Interface for read requests
wire[31:0]  ashi_rindx;     // Input   Read register-index
wire[31:0]  ashi_raddr;     // Input:  Read-address
wire        ashi_read;      // Input:  1 = Handle a read request
reg[31:0]   ashi_rdata;     // Output: Read data
reg[1:0]    ashi_rresp;     // Output: Read-response (OKAY, DECERR, SLVERR);
wire        ashi_ridle;     // Output: 1 = Read state machine is idle
//==========================================================================

// The state of the state-machines that handle AXI4-Lite read and AXI4-Lite write
reg ashi_write_state, ashi_read_state;

// The AXI4 slave state machines are idle when in state 0 and their "start" signals are low
assign ashi_widle = (ashi_write == 0) && (ashi_write_state == 0);
assign ashi_ridle = (ashi_read  == 0) && (ashi_read_state  == 0);
   
// These are the valid values for ashi_rresp and ashi_wresp
localparam OKAY   = 0;
localparam SLVERR = 2;
localparam DECERR = 3;

// The address mask is 'AW' 1-bits in a row
localparam ADDR_MASK = (1 << AW) - 1;

// This will be a 1 when a sequence error of detected
reg seq_error;

// This strobes high for a cycle to clear various counters
reg clear_counters;

// Used to count-down the reset time
reg[15:0] reset_countdown;

// This is active high
wire reset_out = (resetn == 0) | (reset_countdown != 0);
 
// resetn_out is the active-low version of reset_out
always @(posedge clk) resetn_out <= ~reset_out;

// These bits are 1 if DDR RAM banks passed initial calibration
wire[1:0] ddr_cal;

// This is a '1' if the QSFP port has achieved PCS alignment with the peer
wire pcs_aligned;

// This is a countdown timer
reg[31:0] pause_pci_counter;

// PCI output is paused while this counter is non-zero
assign pause_pci = (pause_pci_counter != 0);

//=============================================================================
// This block records a pci_range_error when we see the strobe
//=============================================================================
reg pci_range_err;
//-----------------------------------------------------------------------------
always @(posedge clk) begin
    if (resetn_out == 0 || clear_counters)
        pci_range_err <= 0;
    else if (pci_range_err_strb)
        pci_range_err <= 1;
end
//=============================================================================


//=============================================================================
// Count the number of good packets
//=============================================================================
reg[63:0] good_packets;
//-----------------------------------------------------------------------------
always @(posedge clk) begin
    if (resetn_out == 0 || clear_counters)
        good_packets <= 0;
    else if (good_packet_strb)
        good_packets <= good_packets + 1;
end
//=============================================================================


//=============================================================================
// Count the number of bad packets
//=============================================================================
reg[63:0] bad_packets;
//-----------------------------------------------------------------------------
always @(posedge clk) begin
    if (resetn_out == 0 || clear_counters)
        bad_packets <= 0;
    else if (bad_packet_strb)
        bad_packets <= bad_packets + 1;
end
//=============================================================================


//=============================================================================
// This block monitors for sequence errors
//
// When packets are generated with the built-in packet generator, the high
// 32 bits of TDATA always contain a counter.  If any data cycle occurs where
// that counter is wrong, it indicates that something went awry in the buffer.
//=============================================================================
wire[31:0] seq_data = seq_axis_tdata[64*8-1 -: 32];
reg [31:0] seq_prior;
//-----------------------------------------------------------------------------
always @(posedge clk) begin
    if (resetn_out == 0 || clear_counters)
        seq_error <= 0;

    else if (seq_axis_tvalid & seq_axis_tready) begin

        if (seq_data != 0 && seq_data != (seq_prior+1))
            seq_error <= 1;

        seq_prior <= seq_data;

    end
end
//=============================================================================


//==========================================================================
// This state machine handles AXI4-Lite write requests
//==========================================================================
always @(posedge clk) begin

    gen_packets    <= 0;
    clear_counters <= 0;
    xmit_start     <= 0;

    // This counts down to zero and control the duration of resetn_out
    if (reset_countdown) reset_countdown <= reset_countdown - 1;

    // This counts down to zero to control the duration of pci_pause
    if (pause_pci_counter) pause_pci_counter <= pause_pci_counter - 1;

    // If we're in reset, initialize important registers
    if (resetn == 0) begin
        ashi_write_state  <= 0;
        pci_base          <= 64'h1_0000_0000;
        pci_size          <= 64'h1_0000_0000;
        xmit_src_addr     <= 64'h1_0000_0000;
        xmit_dst_addr     <= 0;
        xmit_byte_count   <= 64'h10_0000;
        loopback          <= 0;
        pause_pci_counter <= 0;
    end
    
    // Otherwise, we're not in reset...
    else case (ashi_write_state)
        
        // If an AXI write-request has occured...
        0:  if (ashi_write) begin
       
                // Assume for the moment that the result will be OKAY
                ashi_wresp <= OKAY;              
            
                // ashi_windex = index of register to be written
                case (ashi_windx)
               
                    REG_PACKET_COUNT_H:
                        begin
                            packet_count[63:32] <= ashi_wdata;
                        end

                    REG_PACKET_COUNT_L:
                        begin
                            packet_count[31:00] <= ashi_wdata;
                            gen_packets         <= 1;
                        end

                    REG_PCI_BASE_H:     pci_base[63:32]   <= ashi_wdata;
                    REG_PCI_BASE_L:     pci_base[31:00]   <= ashi_wdata;                    
                    REG_PCI_SIZE_H:     pci_size[63:32]   <= ashi_wdata;
                    REG_PCI_SIZE_L:     pci_size[31:00]   <= ashi_wdata; 
                    REG_LOOPBACK:       loopback          <= ashi_wdata;
                    REG_RESET:          reset_countdown   <= 1000;                  
                    REG_PAUSE_PCI:      pause_pci_counter <= ashi_wdata;
                    REG_CLEAR_COUNTERS: clear_counters    <= 1;

                    REG_XMIT_SRCADDR_H: xmit_src_addr  [63:32] <= ashi_wdata;
                    REG_XMIT_SRCADDR_L: xmit_src_addr  [31:00] <= ashi_wdata;
                    REG_XMIT_DSTADDR_H: xmit_dst_addr  [63:32] <= ashi_wdata;
                    REG_XMIT_DSTADDR_L: xmit_dst_addr  [31:00] <= ashi_wdata;
                    REG_XMIT_SIZE_H:    xmit_byte_count[63:32] <= ashi_wdata;
                    REG_XMIT_SIZE_L:    xmit_byte_count[31:00] <= ashi_wdata;
                    REG_XMIT_START:     xmit_start             <= ashi_wdata[0];

                    // Writes to any other register are a decode-error
                    default: ashi_wresp <= DECERR;
                endcase
            end

        // Dummy state, doesn't do anything
        1: ashi_write_state <= 0;

    endcase
end
//==========================================================================



//==========================================================================
// World's simplest state machine for handling AXI4-Lite read requests
//==========================================================================
always @(posedge clk) begin

    // If we're in reset, initialize important registers
    if (resetn == 0) begin
        ashi_read_state <= 0;
    
    // If we're not in reset, and a read-request has occured...        
    end else if (ashi_read) begin
   
        // Assume for the moment that the result will be OKAY
        ashi_rresp <= OKAY;              
        
        // ashi_rindex = index of register to be read
        case (ashi_rindx)
            
            // Allow a read from any valid register                
            REG_PACKET_COUNT_H: ashi_rdata <= 0;
            REG_PACKET_COUNT_L: ashi_rdata <= (generator_idle == 0);
            REG_HWMARK_0H:      ashi_rdata <= hwm_0[63:32];
            REG_HWMARK_0L:      ashi_rdata <= hwm_0[31:00];
            REG_HWMARK_1H:      ashi_rdata <= hwm_1[63:32];
            REG_HWMARK_1L:      ashi_rdata <= hwm_1[31:00];
            REG_PCI_BASE_H:     ashi_rdata <= pci_base[63:32];
            REG_PCI_BASE_L:     ashi_rdata <= pci_base[31:00];
            REG_PCI_SIZE_H:     ashi_rdata <= pci_size[63:32];
            REG_PCI_SIZE_L:     ashi_rdata <= pci_size[31:00];
            REG_LOOPBACK:       ashi_rdata <= loopback;

            REG_ERRORS:         ashi_rdata <= 
                                {
                                    seq_error,
                                    overflow_1,
                                    overflow_0,
                                    pci_range_err                                   
                                };

            REG_RESET:          ashi_rdata <= reset_out;
            REG_GOOD_PACKETS_H: ashi_rdata <= good_packets[63:32];
            REG_GOOD_PACKETS_L: ashi_rdata <= good_packets[31:00];
            REG_BAD_PACKETS_H:  ashi_rdata <= bad_packets[63:32];
            REG_BAD_PACKETS_L:  ashi_rdata <= bad_packets[31:00];

            REG_STATUS:         ashi_rdata <=
                                {
                                    ddr_cal,
                                    pcs_aligned
                                };

            REG_PAUSE_PCI:      ashi_rdata <= pause_pci;

            REG_XMIT_SRCADDR_H: ashi_rdata <= xmit_src_addr  [63:32];
            REG_XMIT_SRCADDR_L: ashi_rdata <= xmit_src_addr  [31:00];
            REG_XMIT_DSTADDR_H: ashi_rdata <= xmit_dst_addr  [63:32];
            REG_XMIT_DSTADDR_L: ashi_rdata <= xmit_dst_addr  [31:00];
            REG_XMIT_SIZE_H:    ashi_rdata <= xmit_byte_count[63:32];
            REG_XMIT_SIZE_L:    ashi_rdata <= xmit_byte_count[31:00];
            REG_XMIT_START:     ashi_rdata <= (xmit_idle == 0);

            // Reads of any other register are a decode-error
            default: ashi_rresp <= DECERR;

        endcase
    end
end
//==========================================================================


//==========================================================================
// These synchronize various signals into our clock domain
//==========================================================================
cdc_single i_sync_ddr_calib_0  (async_ddr_cal_0,   clk, ddr_cal[0]);
cdc_single i_sync_ddr_calib_1  (async_ddr_cal_1,   clk, ddr_cal[1]);
cdc_single i_sync_pcs_alignment(async_pcs_aligned, clk, pcs_aligned);
//==========================================================================


//==========================================================================
// This connects us to an AXI4-Lite slave core
//==========================================================================
axi4_lite_slave#(ADDR_MASK) i_axi4lite_slave
(
    .clk            (clk),
    .resetn         (resetn),
    
    // AXI AW channel
    .AXI_AWADDR     (S_AXI_AWADDR),
    .AXI_AWVALID    (S_AXI_AWVALID),   
    .AXI_AWREADY    (S_AXI_AWREADY),
    
    // AXI W channel
    .AXI_WDATA      (S_AXI_WDATA),
    .AXI_WVALID     (S_AXI_WVALID),
    .AXI_WSTRB      (S_AXI_WSTRB),
    .AXI_WREADY     (S_AXI_WREADY),

    // AXI B channel
    .AXI_BRESP      (S_AXI_BRESP),
    .AXI_BVALID     (S_AXI_BVALID),
    .AXI_BREADY     (S_AXI_BREADY),

    // AXI AR channel
    .AXI_ARADDR     (S_AXI_ARADDR), 
    .AXI_ARVALID    (S_AXI_ARVALID),
    .AXI_ARREADY    (S_AXI_ARREADY),

    // AXI R channel
    .AXI_RDATA      (S_AXI_RDATA),
    .AXI_RVALID     (S_AXI_RVALID),
    .AXI_RRESP      (S_AXI_RRESP),
    .AXI_RREADY     (S_AXI_RREADY),

    // ASHI write-request registers
    .ASHI_WADDR     (ashi_waddr),
    .ASHI_WINDX     (ashi_windx),
    .ASHI_WDATA     (ashi_wdata),
    .ASHI_WRITE     (ashi_write),
    .ASHI_WRESP     (ashi_wresp),
    .ASHI_WIDLE     (ashi_widle),

    // ASHI read registers
    .ASHI_RADDR     (ashi_raddr),
    .ASHI_RINDX     (ashi_rindx),
    .ASHI_RDATA     (ashi_rdata),
    .ASHI_READ      (ashi_read ),
    .ASHI_RRESP     (ashi_rresp),
    .ASHI_RIDLE     (ashi_ridle)
);
//==========================================================================



endmodule
