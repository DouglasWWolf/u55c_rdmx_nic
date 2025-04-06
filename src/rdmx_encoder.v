//====================================================================================
//                        ------->  Revision History  <------
//====================================================================================
//
//   Date     Who   Ver  Changes
//====================================================================================
// 20-Mar-25  DWW     1  Initial creation
//====================================================================================

/*
    This encodes an RDMX header
*/

module rdmx_encoder
(
    input [ 63:0] rdmx_target_addr,
    input [ 15:0] payload_length,
    output[511:0] le_rdmx_header
);

genvar i;

// The length (in bytes) of a standard header for an IP packet
localparam IP_HDR_LEN = 20;

// The length (in bytes) of a standard header for a UDP packet
localparam UDP_HDR_LEN = 8;

// The total number of bytes in the RDMX header, including reserved space
localparam RDMX_HDR_LEN = 22;

// The source UDP ports
localparam[15:0] SOURCE_PORT = 1000;
       
// The destination port on the remote server  
localparam[15:0] REMOTE_SERVER_PORT = 32002;

//=============================================================================
// Hard-coded configurable settings
//=============================================================================
localparam[7:0] SRC_MAC = 0;

localparam[7:0] SRC_IP0 = 10;
localparam[7:0] SRC_IP1 =  1;
localparam[7:0] SRC_IP2 =  1;
localparam[7:0] SRC_IP3 =  1;

localparam[7:0] DST_IP0 = 255;
localparam[7:0] DST_IP1 = 255;
localparam[7:0] DST_IP2 = 255;
localparam[7:0] DST_IP3 = 255;
//=============================================================================


// The statically declared ethernet header fields
localparam[47:0] eth_dst_mac    = {48'hFFFFFFFFFFFF};
localparam[47:0] eth_src_mac    = {40'hC400AD0000, SRC_MAC};
localparam[15:0] eth_frame_type = 16'h0800;

// The statically declared IPv4 header fields
localparam[15:0] ip4_ver_dsf    = 16'h4500;
localparam[15:0] ip4_id         = 16'hDEAD;
localparam[15:0] ip4_flags      = 16'h4000;
localparam[15:0] ip4_ttl_prot   = 16'h4011;
localparam[15:0] ip4_srcip_h    = {SRC_IP0, SRC_IP1};
localparam[15:0] ip4_srcip_l    = {SRC_IP2, SRC_IP3};
localparam[15:0] ip4_dstip_h    = {DST_IP0, DST_IP1};
localparam[15:0] ip4_dstip_l    = {DST_IP2, DST_IP3};

// The statically declared UDP header fields
localparam[15:0] udp_src_port   = SOURCE_PORT;
localparam[15:0] udp_dst_port   = REMOTE_SERVER_PORT;
localparam[15:0] udp_checksum   = 0;

// 2 bytes of magic number
localparam[15:0] rdmx_magic = 16'h0122;

// 6 bytes of reserved area in the RDMX header
localparam[6*8-1:0] rdmx_reserved = 0;

// Compute both the IPv4 packet length and UDP packet length
wire[15:0] ip4_length = IP_HDR_LEN + UDP_HDR_LEN + RDMX_HDR_LEN + payload_length;
wire[15:0] udp_length =              UDP_HDR_LEN + RDMX_HDR_LEN + payload_length;

// Compute the 32-bit version of the IPv4 header checksum
wire[31:0] ip4_cs32 = ip4_ver_dsf
                    + ip4_id
                    + ip4_flags
                    + ip4_ttl_prot
                    + ip4_srcip_h
                    + ip4_srcip_l
                    + ip4_dstip_h
                    + ip4_dstip_l
                    + ip4_length;

// Compute the 16-bit IPv4 checksum
wire[15:0] ip4_checksum = ~(ip4_cs32[15:0] + ip4_cs32[31:16]);

// This is the RDMX user field of the outgoing packet
wire[31:0] rdmx_user_field  = 0;

// This number increments by 1 on every packet
reg[15:0] rdmx_seq_num;

// This is the 64-byte big-endian packet header for an RDMX packet
wire[511:0] be_rdmx_header =
{
    // Ethernet header fields - 14 bytes
    eth_dst_mac,
    eth_src_mac,
    eth_frame_type,

    // IPv4 header fields - 20 bytes
    ip4_ver_dsf,
    ip4_length,
    ip4_id,
    ip4_flags,
    ip4_ttl_prot,
    ip4_checksum,
    ip4_srcip_h,
    ip4_srcip_l,
    ip4_dstip_h,
    ip4_dstip_l,

    // UDP header fields - 8 bytes
    udp_src_port,
    udp_dst_port,
    udp_length,
    udp_checksum,
    
    // RDMX header fields - 22 bytes
    rdmx_magic,
    rdmx_target_addr,
    rdmx_seq_num,
    rdmx_user_field,
    rdmx_reserved
};


// Byte-swap the big-endian RDMX header to obtain a little-endian version
for (i=0; i<64; i=i+1) begin
    assign le_rdmx_header[i*8 +:8] = be_rdmx_header[(63-i)*8 +:8];
end

endmodule