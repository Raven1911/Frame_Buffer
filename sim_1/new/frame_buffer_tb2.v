`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/27/2025 09:45:43 PM
// Design Name: 
// Module Name: frame_buffer_tb2
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////



//----------------------------------------------------------------------------------
// Testbench Parameters
//----------------------------------------------------------------------------------
`define TB_ADDR_WIDTH     12       // Total address space (4096 addresses)
`define TB_DATA_WIDTH     16       // Data width
`define TB_NUMBER_BRAM    4        // Number of BRAM sub-modules
`define TB_DEPTH_SIZE     1024     // Depth of each BRAM (1024 entries)
`define TB_MODE           2        // Mode: Dual Read / Single Write

// Global addresses for testing BRAM boundaries:
// BRAM 0: Address 0 to 1023 (0x000 to 0x3FF)
// BRAM 1: Address 1024 to 2047 (0x400 to 0x7FF)
// BRAM 2: Address 2048 to 3071 (0x800 to 0xBFF)
// BRAM 3: Address 3072 to 4095 (0xC00 to 0xFFF)

module frame_buffer_tb2;

    // Clock and Reset Signals
    reg                     clk_i;
    reg                     resetn_i;

    // Write Port 0 (Single Write Port in MODE 2)
    reg                     wr0_i;
    reg [`TB_ADDR_WIDTH-1:0] addr_wr0;
    reg [`TB_DATA_WIDTH-1:0] Data_in0;
    wire                     wr1_i;  // Unused in MODE 2
    reg [`TB_ADDR_WIDTH-1:0] addr_wr1; // Unused in MODE 2
    reg [`TB_DATA_WIDTH-1:0] Data_in1; // Unused in MODE 2

    // Read Ports
    reg [`TB_ADDR_WIDTH-1:0] addr_rd0;
    reg [`TB_ADDR_WIDTH-1:0] addr_rd1;
    wire [`TB_DATA_WIDTH-1:0] Data_out0;
    wire [`TB_DATA_WIDTH-1:0] Data_out1;
    
    // Clock Generation
    initial begin
        clk_i = 0;
        forever #5 clk_i = ~clk_i; // 10ns clock period (100MHz)
    end

    // Instantiate Unit Under Test (UUT)
    frame_buffer # (
        .ADDR_WIDTH     (`TB_ADDR_WIDTH),
        .DATA_WIDTH     (`TB_DATA_WIDTH),
        .NUMBER_BRAM    (`TB_NUMBER_BRAM),
        .DEPTH_SIZE     (`TB_DEPTH_SIZE),
        .MODE           (`TB_MODE)
    ) uut (
        .clk_i    (clk_i),
        .resetn_i (resetn_i),

        .wr0_i    (wr0_i),
        .wr1_i    (wr1_i),

        .addr_wr0 (addr_wr0),
        .addr_wr1 (addr_wr1),
        .addr_rd0 (addr_rd0),
        .addr_rd1 (addr_rd1),

        .Data_in0 (Data_in0),
        .Data_in1 (Data_in1),
        .Data_out0(Data_out0),
        .Data_out1(Data_out1)
    );
    
    // Drive unused inputs for MODE 2
    assign wr1_i = 1'b0;
    
    // Test Sequence
    initial begin
        // Initialize
        addr_wr0 = 0;
        Data_in0 = 0;
        wr0_i    = 0;
        addr_rd0 = 0;
        addr_rd1 = 0;
        addr_wr1 = 0;
        Data_in1 = 0;

        $display("--- Starting Frame Buffer Test (MODE 2: Dual Read / Single Write) ---");
        
        // Reset sequence
        resetn_i = 0;
        #20;                  // Wait 2 clock cycles
        resetn_i = 1;
        $display("@%0t: Reset released.", $time);

        // -----------------------------------------------------------
        // PHASE 1: Write Data to all 4 BRAMs via Port 0
        // -----------------------------------------------------------
        #10;
        $display("\n--- PHASE 1: Writing unique data to all BRAM banks via Port 0 ---");

        // Write to BRAM 0 (Address 0)
        addr_wr0 = 12'h000; // Global Address 0
        Data_in0 = 16'hAAAA;
        wr0_i    = 1;
        #10;
        $display("@%0t: Write BRAM 0 (Addr %h, Data %h)", $time, addr_wr0, Data_in0);

        // Write to BRAM 1 (Address 1024)
        addr_wr0 = 12'h400; // Global Address 1024
        Data_in0 = 16'hBBBB;
        #10;
        $display("@%0t: Write BRAM 1 (Addr %h, Data %h)", $time, addr_wr0, Data_in0);

        // Write to BRAM 2 (Address 2048)
        addr_wr0 = 12'h800; // Global Address 2048
        Data_in0 = 16'hCCCC;
        #10;
        $display("@%0t: Write BRAM 2 (Addr %h, Data %h)", $time, addr_wr0, Data_in0);

        // Write to BRAM 3 (Address 3072)
        addr_wr0 = 12'hC00; // Global Address 3072
        Data_in0 = 16'hDDDD;
        #10;
        $display("@%0t: Write BRAM 3 (Addr %h, Data %h)", $time, addr_wr0, Data_in0);

        wr0_i    = 0;
        #10;
        
        // -----------------------------------------------------------
        // PHASE 2: Read Data from all 4 BRAMs
        // -----------------------------------------------------------
        $display("\n--- PHASE 2: Reading back data (Latency = 2 Cycles) ---");

        // Cycle N: Apply addresses
        addr_rd0 = 12'h000; // Read BRAM 0 for Port 0
        addr_rd1 = 12'h400; // Read BRAM 1 for Port 1
        $display("@%0t: Applying Read Addr 0: %h (Expect AAAA), Addr 1: %h (Expect BBBB)", $time, addr_rd0, addr_rd1);
        #10;

        // Cycle N+1: BRAM data available (Data_out still incorrect)
        addr_rd0 = 12'h800; // Read BRAM 2 for Port 0
        addr_rd1 = 12'hC00; // Read BRAM 3 for Port 1
        $display("@%0t: Applying Read Addr 0: %h (Expect CCCC), Addr 1: %h (Expect DDDD)", $time, addr_rd0, addr_rd1);
        #10;

        // Cycle N+2: Data is available for the addresses applied at Cycle N
        $display("\n@%0t: Read Check 1 (Data is for Addr N):", $time);
        if (Data_out0 === 16'hAAAA) $display("    [PASS] Port 0 Data_out0: %h", Data_out0);
        else $display("    [FAIL] Port 0 Data_out0: %h (Expected AAAA)", Data_out0);
        
        if (Data_out1 === 16'hBBBB) $display("    [PASS] Port 1 Data_out1: %h", Data_out1);
        else $display("    [FAIL] Port 1 Data_out1: %h (Expected BBBB)", Data_out1);
        
        #10;

        // Cycle N+3: Data is available for the addresses applied at Cycle N+1
        $display("\n@%0t: Read Check 2 (Data is for Addr N+1):", $time);
        if (Data_out0 === 16'hCCCC) $display("    [PASS] Port 0 Data_out0: %h", Data_out0);
        else $display("    [FAIL] Port 0 Data_out0: %h (Expected CCCC)", Data_out0);

        if (Data_out1 === 16'hDDDD) $display("    [PASS] Port 1 Data_out1: %h", Data_out1);
        else $display("    [FAIL] Port 1 Data_out1: %h (Expected DDDD)", Data_out1);
        

        #10;
        $display("\n--- Test complete ---");
        $finish;
    end
    
endmodule

