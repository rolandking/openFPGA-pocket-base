`timescale 1ns/1ps
import pocket_pkg::rgb_t;

module video_test(
    input  wire       video_rgb_clock,
    input  wire       reset_n,
    output wire[23:0] video_rgb,
    output wire       video_de,
    output wire       video_skip,
    output wire       video_vs,
    output wire       video_hs,

    input  wire[1:0]  mode
);

    logic [8:0] x, y;
    logic [8:0] y_pixels, y_bottom = 9'd2;

    // generate x & y counts 0-511, at 60hz that's 512*512*60 = 15,728,860hz
    // pixel clock
    always_ff @(posedge video_rgb_clock) begin
        x <= x + 9'd1;
        if(x=='0) begin
            y <= y + 9'd1;
        end

        // register this at frame start
        if(video_vs) begin
            case (mode)
                2'd0: begin
                    // 320 pixels works 
                    y_pixels <= 9'd320;
                    y_bottom <= 9'd2;
                end
                2'd1: begin 
                    // 360 pixels you lose the bottom
                    y_pixels <= 9'd360;
                    y_bottom <= 9'd2;
                end
                2'd2: begin
                    // show that even if scaled down you still lose the bottom
                    y_pixels <= 9'd360;
                    y_bottom <= 9'd2;
                end
                2'd3: begin
                    // increase the bottom to 10px and you get your 2px border
                    // suggesting that 8px have been lost
                    y_pixels <= 9'd360;
                    y_bottom <= 9'd10;
                end
            endcase
        end
    end

    rgb_t rgb_in;


    localparam logic[8:0] x_start = 9'd50;
    localparam logic[8:0] x_end   = 9'd50 + 9'd400;
    localparam logic[8:0] y_start = 9'd50;

    logic [8:0] y_end;
    always_comb begin
        y_end = y_start + y_pixels;
    end

    logic frame_bits_cycle, border_cycle;

    always_comb begin
        video_vs   = (x == '0) && (y == '0);
        video_hs   = (x == 9'd10 );
        video_skip = '0;

        video_de         = 
            ( x >=  x_start        ) && ( x <   x_end        ) && 
            ( y >=  y_start        ) && ( y <   y_end        );

        border_cycle     = 
            ( x <  (x_start + 9'd2)) || ( x >= (x_end - 9'd2    )) || 
            ( y <  (y_start + 9'd2)) || ( y >= (y_end - y_bottom));

        frame_bits_cycle = ( x == x_end );
    end

    always_comb begin
        if(frame_bits_cycle) begin
            video_rgb[23:13] = mode;
            video_rgb[12:3]  = '0;
            video_rgb[2:0]   = 3'd0;
        end else begin
            if(video_de) begin
                video_rgb = border_cycle ? '1 : 24'h10ff10;
            end else begin
                video_rgb = '0;
            end
        end
    end

endmodule 



