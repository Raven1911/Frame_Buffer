`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/27/2025 08:45:50 PM
// Design Name: 
// Module Name: frame_buffer_tb1
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

module frame_buffer_tb1;

    // --- Khai báo tham số ---
    localparam ADDR_WIDTH   = 32;
    localparam DATA_WIDTH   = 16;
    localparam NUMBER_BRAM  = 10;
    localparam DEPTH_SIZE   = 1024; // Phạm vi mỗi BRAM
    localparam CLK_PERIOD   = 10;
    
    // Tổng dung lượng địa chỉ: 10 * 1024 = 10240
    // BRAM 0: [0 - 1023]
    // BRAM 1: [1024 - 2047]
    // BRAM 9: [9216 - 10239]

    // --- Tín hiệu đầu vào/ra của DUT (frame_buffer) ---
    reg             clk_i;
    reg             resetn_i;

    reg             wr0_i;
    reg             wr1_i;

    reg   [ADDR_WIDTH-1:0]   addr_wr0;
    reg   [ADDR_WIDTH-1:0]   addr_wr1;
    reg   [ADDR_WIDTH-1:0]   addr_rd0;
    reg   [ADDR_WIDTH-1:0]   addr_rd1;

    reg   [DATA_WIDTH-1:0]   Data_in0;
    reg   [DATA_WIDTH-1:0]   Data_in1;
    wire  [DATA_WIDTH-1:0]   Data_out0;
    wire  [DATA_WIDTH-1:0]   Data_out1;

    // --- Khởi tạo DUT (Device Under Test) ---
    frame_buffer#(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .NUMBER_BRAM(NUMBER_BRAM),
        .DEPTH_SIZE(DEPTH_SIZE),
        .MODE(1) // Đặt MODE = 1 theo yêu cầu
    ) dut (
        .clk_i(clk_i),
        .resetn_i(resetn_i),
        .wr0_i(wr0_i),
        .wr1_i(wr1_i),
        .addr_wr0(addr_wr0),
        .addr_wr1(addr_wr1),
        .addr_rd0(addr_rd0),
        .addr_rd1(addr_rd1),
        .Data_in0(Data_in0),
        .Data_in1(Data_in1),
        .Data_out0(Data_out0),
        .Data_out1(Data_out1)
    );

    // --- Tạo Clock ---
    initial begin
        clk_i = 1'b0;
        forever #(CLK_PERIOD/2) clk_i = ~clk_i;
    end

    // --- Khởi tạo và Dãy kích hoạt (Test Sequence) ---
    initial begin
        $dumpfile("frame_buffer_tb.vcd");
        $dumpvars(0, frame_buffer_tb1);

        // 1. Reset
        resetn_i = 1'b0;
        wr0_i = 1'b0;
        wr1_i = 1'b0;
        addr_wr0 = 0;
        addr_wr1 = 0;
        addr_rd0 = 0;
        addr_rd1 = 0;
        Data_in0 = 0;
        Data_in1 = 0;

        # (CLK_PERIOD * 2) 
        resetn_i = 1'b1;
        $display("--- Bắt đầu mô phỏng: MODE 1 (Dual Port) ---");

        // --- BƯỚC 1: GHI DỮ LIỆU ---

        // Ghi Port 0: BRAM 0, Địa chỉ 512, Data AAAA
        # CLK_PERIOD
        $display("-------------------------------------------");
        $display("T = %0t: Ghi Port 0 (BRAM 0). Addr=512, Data=AAAA", $time);
        wr0_i = 1'b1;
        addr_wr0 = 512; 
        Data_in0 = 16'hAAAA;

        // Ghi Port 1: BRAM 1, Địa chỉ 1024 + 512 = 1536, Data 5555
        $display("T = %0t: Ghi Port 1 (BRAM 1). Addr=1536, Data=5555", $time);
        wr1_i = 1'b1;
        addr_wr1 = 1024 + 512; // 1536
        Data_in1 = 16'h5555;
        
        # CLK_PERIOD
        wr0_i = 1'b0; // Dừng ghi
        wr1_i = 1'b0;

        // --- BƯỚC 2: ĐỌC RIÊNG LẺ (Xác minh Ghi) ---

        // Đọc Port 0: Đọc 512 (BRAM 0)
        # CLK_PERIOD
        $display("-------------------------------------------");
        $display("T = %0t: Đọc Port 0 (BRAM 0). Addr_rd0=512", $time);
        addr_rd0 = 512;
        addr_rd1 = 0; // Đảm bảo Port 1 không đọc địa chỉ quan trọng

        # CLK_PERIOD // Đọc đồng bộ (Data_out0 trễ 1 clock)
        $display("T = %0t: Data_out0=%h (Expect AAAA)", $time, Data_out0);
        
        // Đọc Port 1: Đọc 1536 (BRAM 1)
        # CLK_PERIOD
        $display("T = %0t: Đọc Port 1 (BRAM 1). Addr_rd1=1536", $time);
        addr_rd0 = 0; // Đảm bảo Port 0 không đọc địa chỉ quan trọng
        addr_rd1 = 1024 + 512; // 1536

        # CLK_PERIOD // Đọc đồng bộ (Data_out1 trễ 1 clock)
        $display("T = %0t: Data_out1=%h (Expect 5555)", $time, Data_out1);

        // --- BƯỚC 3: ĐỌC VÀ GHI ĐỒNG THỜI (Dual Port) ---

        // Ghi Port 0: BRAM 9 (Địa chỉ 9216 + 10 = 9226)
        // Đọc Port 1: BRAM 0 (Địa chỉ 512)
        # CLK_PERIOD
        $display("-------------------------------------------");
        $display("T = %0t: Hoạt động đồng thời:", $time);
        // Ghi Port 0
        wr0_i = 1'b1;
        addr_wr0 = 9216 + 10; // 9226 (BRAM 9)
        Data_in0 = 16'hFFFF;
        $display("T = %0t: Port 0: Ghi FFFF vào Addr=9226", $time);
        
        // Đọc Port 1
        addr_rd1 = 512; // Vẫn đang đọc BRAM 0
        $display("T = %0t: Port 1: Đọc Addr=512 (BRAM 0)", $time);

        # CLK_PERIOD // Sau 1 clock chu kỳ
        $display("T = %0t: Đã hoàn tất ghi Port 0. Data_out1=%h (Expect AAAA)", $time, Data_out1);
        wr0_i = 1'b0; // Dừng ghi Port 0

        // --- BƯỚC 4: XÁC MINH GHI (PORT 0) VÀ ĐỌC (PORT 1) ---

        // Đọc Port 0: Xác minh Data FFFF đã ghi
        # CLK_PERIOD
        $display("-------------------------------------------");
        $display("T = %0t: Đọc Port 0: Addr_rd0=9226 (BRAM 9)", $time);
        addr_rd0 = 9216 + 10;
        addr_rd1 = 0;

        # CLK_PERIOD
        $display("T = %0t: Data_out0=%h (Expect FFFF)", $time, Data_out0);

        # CLK_PERIOD
        $display("--- Mô phỏng kết thúc ---");
        $finish;
    end

endmodule


