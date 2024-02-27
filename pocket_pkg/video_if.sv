`timescale 1ns/1ps

interface video_if(
    output logic rgb_clk,
    output logic rgb_clk_90
);

    pocket::rgb_t rgb;
    logic         de;
    logic         skip;
    logic         vs;
    logic         hs;

    function automatic tie_off();
        rgb_clk    = '0;
        rgb_clk_90 = '0;
        rgb        = '0;
        de         = '0;
        skip       = '0;
        vs         = '0;
        hs         = '0;
    endfunction

endinterface

module video_connect (
    output pocket::rgb_t rgb,
    output wire          de,
    output wire          skip,
    output wire          vs,
    output wire          hs,

    video_if        video
);
    always_comb begin
        rgb          = video.rgb;
        de           = video.de;
        skip         = video.skip;
        vs           = video.vs;
        hs           = video.hs;
    end

endmodule

`define VIDEO_CONNECT_IN_OUT( _i, _o)  \
    _o.rgb          = _i.rgb;          \
    _o.de           = _i.de;           \
    _o.skip         = _i.skip;         \
    _o.vs           = _i.vs;           \
    _o.hs           = _i.hs;           \

/*
 *   74mhz / 4 / 50Hz = 370,000
 *   = 740 * 500
 *
 *   make the display 400 x 360
 *   put HS at 50, VS at (0,50)
 *   DE = (HS >= 100 & HS < 500) & (VS >= 100 && VS < 460)
 */

module video_dummy(
    video_if   video
);
    logic [9:0] hcount;
    logic [8:0] vcount;

    always_ff @(posedge video.rgb_clk) begin
        if(hcount == 10'd739) begin
            hcount <= '0;
            if(vcount == 9'd499) begin
                vcount <= '0;
            end else begin
                vcount <= vcount + 9'h1;
            end
        end else begin
            hcount <= hcount + 10'h1;
        end
    end

    pocket::rgb_t rgb_out;
    always_ff @(posedge video.rgb_clk) begin
        if(video.de) begin
            if(rgb_out.red >=254) begin
                if(rgb_out.green >= 254) begin
                    if(rgb_out.blue >= 254) begin
                    end else begin
                        rgb_out.blue <= rgb_out.blue + 8'd2;
                    end
                end else begin
                    rgb_out.green <= rgb_out.green + 8'd2;
                end
            end else begin
                rgb_out.red <= rgb_out.red + 8'd2;
            end
        end else begin
            rgb_out <= '0;
        end
    end

    always_comb begin
        video.hs    = hcount == 9'd50;
        video.vs    = vcount == 8'd50;
        video.de    = (hcount >= 10'd100 && hcount < 10'd500 && vcount >= 9'd100 && vcount < 9'd460);
        video.skip  = 0;
        video.rgb   = video.de ? rgb_out : '0;
    end

endmodule
