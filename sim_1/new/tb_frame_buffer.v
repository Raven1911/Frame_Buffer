`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/26/2025 05:26:32 PM
// Design Name: 
// Module Name: tb_frame_buffer
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



module tb_frame_buffer;

    // Parameters (cần khớp với module frame_buffer hoặc điều chỉnh theo ý muốn)
    parameter ADDR_WIDTH 	= 32;
    parameter DATA_WIDTH 	= 16;
    parameter NUMBER_BRAM 	= 10;
    parameter DEPTH_SIZE 	= 1024; // Kích thước mỗi BRAM (1024 * 16 bit = 2KB)

    // Signals for UUT (Unit Under Test)
    reg 	clk_i;
    reg 	wr_i;
    reg 	[ADDR_WIDTH-1:0] addr_wr;
    reg 	[ADDR_WIDTH-1:0] addr_rd;
    reg 	[DATA_WIDTH-1:0] Data_in;
    wire 	[DATA_WIDTH-1:0] Data_out;

    // Instantiate the Unit Under Test (UUT)
    frame_buffer #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .NUMBER_BRAM(NUMBER_BRAM),
        .DEPTH_SIZE(DEPTH_SIZE)
    ) uut (
        .clk_i(clk_i),
        .resetn_i(1'b1),
        .wr0_i(wr_i),
        .addr_wr0(addr_wr),
        .addr_rd0(addr_rd),
        .Data_in0(Data_in),
        .Data_out0(Data_out)
    );

    // Clock generation
    localparam CLK_PERIOD = 10; // 10ns -> 100MHz
    initial begin
        clk_i = 0;
        forever #(CLK_PERIOD/2) clk_i = ~clk_i;
    end

    // Test sequence
    initial begin
        // 1. Initialize signals
        wr_i = 0;
        addr_wr = 0;
        addr_rd = 0;
        Data_in = 16'h0000;
        
        // Wait for a few clock cycles
        repeat (5) @(posedge clk_i);

        // --- Ghi dữ liệu vào BRAM 0 ---
        $display("--- Test Ghi BRAM 0 ---");
        // Địa chỉ: 0 (BRAM 0)
        // Dữ liệu: 16'hAAAA
        wr_i 	= 1;
        addr_wr = 32'h0000_0000; // Địa chỉ 0
        Data_in = 16'hAAAA;
        @(posedge clk_i);
        
        // Địa chỉ: 1023 (BRAM 0)
        // Dữ liệu: 16'h5555
        addr_wr = DEPTH_SIZE - 1; // Địa chỉ cuối cùng của BRAM 0
        Data_in = 16'h5555;
        @(posedge clk_i);
        
        wr_i = 0; // Ngừng ghi

        // --- Ghi dữ liệu vào BRAM 1 ---
        $display("--- Test Ghi BRAM 1 ---");
        // Địa chỉ: 1024 (BRAM 1)
        // Dữ liệu: 16'hBBBB
        wr_i 	= 1;
        addr_wr = DEPTH_SIZE; // Địa chỉ đầu tiên của BRAM 1
        Data_in = 16'hBBBB;
        @(posedge clk_i);

        // Địa chỉ: 2047 (BRAM 1)
        // Dữ liệu: 16'hCCCC
        addr_wr = (DEPTH_SIZE * 2) - 1; // Địa chỉ cuối cùng của BRAM 1
        Data_in = 16'hCCCC;
        @(posedge clk_i);

        wr_i = 0; // Ngừng ghi
        
        // --- Ghi dữ liệu vào BRAM cuối cùng (BRAM 9) ---
        $display("--- Test Ghi BRAM Cuối (9) ---");
        // BRAM 9 bắt đầu từ DEPTH_SIZE * 9 = 1024 * 9 = 9216
        // Địa chỉ: 9216 (BRAM 9)
        // Dữ liệu: 16'hFFFF
        wr_i 	= 1;
        addr_wr = DEPTH_SIZE * (NUMBER_BRAM - 1); 
        Data_in = 16'hFFFF;
        @(posedge clk_i);
        
        wr_i = 0; // Ngừng ghi

        repeat (5) @(posedge clk_i); // Chờ một vài chu kỳ sau ghi
        
        // --- Đọc dữ liệu từ BRAM 0 ---
        $display("--- Test Đọc BRAM 0 ---");
        // Đọc Địa chỉ 0 (Dữ liệu mong muốn: AAAA)
        addr_rd = 32'h0000_0000;
        @(posedge clk_i);
        $display("Đọc BRAM 0, Địa chỉ %0d: Data_out = %h (Expected: AAAA)", addr_rd, Data_out); // Đọc AAAA
        
        // Đọc Địa chỉ 1023 (Dữ liệu mong muốn: 5555)
        addr_rd = DEPTH_SIZE - 1;
        @(posedge clk_i);
        $display("Đọc BRAM 0, Địa chỉ %0d: Data_out = %h (Expected: 5555)", addr_rd, Data_out); // Đọc 5555
        
        // --- Đọc dữ liệu từ BRAM 1 ---
        $display("--- Test Đọc BRAM 1 ---");
        // Đọc Địa chỉ 1024 (Dữ liệu mong muốn: BBBB)
        addr_rd = DEPTH_SIZE;
        @(posedge clk_i);
        $display("Đọc BRAM 1, Địa chỉ %0d: Data_out = %h (Expected: BBBB)", addr_rd, Data_out); // Đọc BBBB

        // Đọc Địa chỉ 2047 (Dữ liệu mong muốn: CCCC)
        addr_rd = (DEPTH_SIZE * 2) - 1;
        @(posedge clk_i);
        $display("Đọc BRAM 1, Địa chỉ %0d: Data_out = %h (Expected: CCCC)", addr_rd, Data_out); // Đọc CCCC

        // --- Đọc dữ liệu từ BRAM cuối cùng (BRAM 9) ---
        $display("--- Test Đọc BRAM Cuối (9) ---");
        // Đọc Địa chỉ 9216 (Dữ liệu mong muốn: FFFF)
        addr_rd = DEPTH_SIZE * (NUMBER_BRAM - 1); 
        @(posedge clk_i);
        $display("Đọc BRAM 9, Địa chỉ %0d: Data_out = %h (Expected: FFFF)", addr_rd, Data_out); // Đọc FFFF

        // Finish simulation
        $display("--- Kết thúc mô phỏng ---");
        $stop;
    end

    // Monitoring (tùy chọn để hiển thị các tín hiệu chính)
    initial begin
        $monitor("Time: %0t, clk_i=%b, wr_i=%b, addr_wr=%0d, Data_in=%h, addr_rd=%0d, Data_out=%h", 
                 $time, clk_i, wr_i, addr_wr, Data_in, addr_rd, Data_out);
    end

endmodule
