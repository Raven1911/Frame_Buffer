`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/26/2025 05:17:15 PM
// Design Name: 
// Module Name: frame_buffer
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



module frame_buffer#(
    parameter ADDR_WIDTH    = 32,
    parameter DATA_WIDTH    = 16,
    parameter NUMBER_BRAM   = 10,
    parameter DEPTH_SIZE    = 1024 // size bram = (DATA_WIDTH * DEPTH_SIZE)/8 (Byte) 
)(

    input                               clk_i,
    input                               resetn_i,

    input                               wr_i,

    input           [ADDR_WIDTH-1:0]    addr_wr, //address global
    input           [ADDR_WIDTH-1:0]    addr_rd, //address global

    input           [DATA_WIDTH-1:0]    Data_in,
    output          [DATA_WIDTH-1:0]    Data_out

    );


    wire            [NUMBER_BRAM-1:0]                    s_wr_in;
    wire            [NUMBER_BRAM*ADDR_WIDTH-1:0]         s_addr_wr;  // address local for each BRAM
    wire            [NUMBER_BRAM*ADDR_WIDTH-1:0]         s_addr_rd;  // address local for each BRAM
    wire            [NUMBER_BRAM*DATA_WIDTH-1:0]         s_Data_in;
    wire            [NUMBER_BRAM*DATA_WIDTH-1:0]         s_Data_out;
    wire            [NUMBER_BRAM-1:0]                    ID_bram_selected;


    // wire            [ADDR_WIDTH-1:0]    dff_addr_rd;
    //delay 2 cycle read
    // register_DFF_dvp #(
    //     .SIZE_BITS(ADDR_WIDTH)
    // ) DFF_DVP_RX (
    //     .clk_i(clk_i),
    //     .resetn_i(resetn_i),
    //     .D_i(addr_rd),
    //     .Q_o(dff_addr_rd)
    // );

    decoder_frame_buffer#(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .NUMBER_BRAM(NUMBER_BRAM),
        .DEPTH_SIZE(DEPTH_SIZE)
    )decoder_frame_buffer_uut(
        //input mem
        .wr_i(wr_i),
        .addr_wr(addr_wr),
        .addr_rd(addr_rd),
        .Data_in(Data_in),
    //decoder port for each bram
        .s_wr_in_o(s_wr_in), 
        .s_addr_wr_o(s_addr_wr),
        .s_addr_rd_o(s_addr_rd),
        .s_Data_in_o(s_Data_in),
        .ID_bram_selected_rd_o(ID_bram_selected)
    );

    // gen block ram
    genvar bram_count;
    generate
        for (bram_count = 0; bram_count < NUMBER_BRAM; bram_count = bram_count + 1) begin : g_bram
            wire [ADDR_WIDTH-1:0]  aw = s_addr_wr [((ADDR_WIDTH*bram_count)+ADDR_WIDTH-1) -: ADDR_WIDTH];
            wire [ADDR_WIDTH-1:0]  ar = s_addr_rd [((ADDR_WIDTH*bram_count)+ADDR_WIDTH-1) -: ADDR_WIDTH];
            wire [DATA_WIDTH-1:0]  din = s_Data_in [((DATA_WIDTH*bram_count)+DATA_WIDTH-1) -: DATA_WIDTH];
            wire                   we  = s_wr_in[bram_count];

            block_ram_frame_buffer #(
                .ADDR_WIDTH (ADDR_WIDTH),   // có thể giảm xuống $clog2(DEPTH_SIZE) nếu muốn gọn địa chỉ local
                .DATA_WIDTH (DATA_WIDTH),
                .DEPTH_SIZE (DEPTH_SIZE)
            ) u_bram (
                .clk_i    (clk_i),
                .wr_i     (we),
                .addr_wr  (aw   - (DEPTH_SIZE*bram_count)),
                .addr_rd  (ar   - (DEPTH_SIZE*bram_count)),
                .Data_in  (din),
                .Data_out (s_Data_out[((DATA_WIDTH*bram_count)+DATA_WIDTH-1) -: DATA_WIDTH])
            );
        end
    endgenerate

    encoder_frame_buffer#(
        .DATA_WIDTH(DATA_WIDTH),
        .NUMBER_BRAM(NUMBER_BRAM)
    )encoder_frame_buffer_uut(
        .clk_i(clk_i),
        .resetn_i(resetn_i),
        .ID_bram_selected_rd_i(ID_bram_selected),
        .s_Data_out_i(s_Data_out),
        .Data_out(Data_out)   
    );





endmodule


module decoder_frame_buffer#(
    parameter ADDR_WIDTH    = 32,
    parameter DATA_WIDTH    = 16, //WORD_SIZE
    parameter NUMBER_BRAM   = 16,
    parameter DEPTH_SIZE    = 262144 // size bram = (WORD_SIZE * DEPTH_SIZE)/8 (Byte) 


)(
    //input mem
    input                               wr_i,

    input           [ADDR_WIDTH-1:0]    addr_wr,
    input           [ADDR_WIDTH-1:0]    addr_rd,
    input           [DATA_WIDTH-1:0]    Data_in,


    //decoder port for each bram
    output          [NUMBER_BRAM-1:0]                             s_wr_in_o, 
    output          [NUMBER_BRAM*ADDR_WIDTH-1:0]                  s_addr_wr_o,
    output          [NUMBER_BRAM*ADDR_WIDTH-1:0]                  s_addr_rd_o,
    output          [NUMBER_BRAM*DATA_WIDTH-1:0]                  s_Data_in_o,
    output          [NUMBER_BRAM-1:0]                             ID_bram_selected_rd_o

);  

    wire [NUMBER_BRAM-1:0] ID_bram_selected_wr;
    wire [NUMBER_BRAM-1:0] ID_bram_selected_rd;
    

    genvar  bram_count;
    //decoder addr_wr   
    generate
        for (bram_count = 0; bram_count < NUMBER_BRAM; bram_count = bram_count + 1) begin
            assign ID_bram_selected_wr[bram_count] = ((addr_wr >= DEPTH_SIZE*bram_count) && (addr_wr < (DEPTH_SIZE*bram_count) + DEPTH_SIZE));
        end
    endgenerate

    //decoder addr_rd   
    generate
        for (bram_count = 0; bram_count < NUMBER_BRAM; bram_count = bram_count + 1) begin
            assign ID_bram_selected_rd[bram_count] = ((addr_rd >= DEPTH_SIZE*bram_count) && (addr_rd < (DEPTH_SIZE*bram_count) + DEPTH_SIZE));
        end
    endgenerate


    //connect awaddr_wr master to bram
    generate
        for (bram_count = 0; bram_count < NUMBER_BRAM; bram_count = bram_count + 1) begin
            assign s_addr_wr_o[((ADDR_WIDTH*bram_count)+ADDR_WIDTH-1) -: ADDR_WIDTH] = (ID_bram_selected_wr[bram_count]) ?  addr_wr : 0;
        end
    endgenerate

    generate
        for (bram_count = 0; bram_count < NUMBER_BRAM; bram_count = bram_count + 1) begin
            assign s_addr_rd_o[((ADDR_WIDTH*bram_count)+ADDR_WIDTH-1) -: ADDR_WIDTH] = (ID_bram_selected_rd[bram_count]) ?  addr_rd : 0;
        end
    endgenerate

    generate
        for (bram_count = 0; bram_count < NUMBER_BRAM; bram_count = bram_count + 1) begin
            assign s_wr_in_o[bram_count] = (ID_bram_selected_wr[bram_count]) ?  wr_i : 0;
        end
    endgenerate

    generate
        for (bram_count = 0; bram_count < NUMBER_BRAM; bram_count = bram_count + 1) begin
            assign s_Data_in_o[((DATA_WIDTH*bram_count)+DATA_WIDTH-1) -: DATA_WIDTH] = (ID_bram_selected_wr[bram_count]) ? Data_in : 0;
        end
    endgenerate



    assign ID_bram_selected_rd_o = ID_bram_selected_rd;


endmodule


module encoder_frame_buffer#(
    parameter DATA_WIDTH    = 16, //WORD_SIZE
    parameter NUMBER_BRAM   = 3
)(  
    input                                       clk_i,
    input                                       resetn_i,
    input       [NUMBER_BRAM-1:0]               ID_bram_selected_rd_i,
    input       [NUMBER_BRAM*DATA_WIDTH-1:0]    s_Data_out_i,
    output  reg [DATA_WIDTH-1:0]                Data_out    

);  

    reg         [NUMBER_BRAM-1:0]  ID_bram_next, ID_bram_reg;

    always @(posedge clk_i) begin
        if (~resetn_i) begin
            ID_bram_reg <= 0;
        end
        else begin
            ID_bram_reg <= ID_bram_next;
        end
        
    end

    integer i;
    always @(*) begin
        ID_bram_next = ID_bram_selected_rd_i;
        Data_out  = {DATA_WIDTH{1'b0}};
        for (i = 0; i < NUMBER_BRAM; i = i + 1) begin  
            Data_out = Data_out | ({DATA_WIDTH{/* ID_bram_selected_rd_i */ID_bram_reg[i]}} & s_Data_out_i[((DATA_WIDTH*i) + DATA_WIDTH -1) -: DATA_WIDTH]);
        end
    end

endmodule


module block_ram_frame_buffer#(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter DEPTH_SIZE = 262144 // size bram = (WORD_SIZE * DEPTH_SIZE)/8 (Byte) 
)(
    input                               clk_i,

    input                               wr_i,

    input           [ADDR_WIDTH-1:0]    addr_wr,
    input           [ADDR_WIDTH-1:0]    addr_rd,

    input           [DATA_WIDTH-1:0]    Data_in,
    output  reg     [DATA_WIDTH-1:0]    Data_out

    );

    reg [DATA_WIDTH-1:0] mem [0:DEPTH_SIZE-1]; //524_288 byte

    always @(posedge clk_i) begin
        if(wr_i) begin
            mem[addr_wr] <= Data_in;
        end
        Data_out <= mem[addr_rd];
    end

endmodule


module register_DFF_dvp#(
    SIZE_BITS = 32
)(  
    input                           clk_i,
    input                           resetn_i,
    input       [SIZE_BITS-1:0]     D_i,

    output  reg [SIZE_BITS-1:0]     Q_o
);
    always @(posedge clk_i, negedge resetn_i) begin
        if (~resetn_i) begin
            Q_o <= 0;
        end
        else begin
            Q_o <= D_i;
        end
    end

endmodule
