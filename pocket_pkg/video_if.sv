`timescale 1ns/1ps

interface video_if(
    output logic rgb_clock,
    output logic rgb_clock_90
);

    pocket::rgb_t rgb;
    logic         de;
    logic         skip;
    logic         vs;
    logic         hs;

    function automatic tie_off();
        rgb_clock    = '0;
        rgb_clock_90 = '0;
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


module video_oneway(
    video_if in,
    video_if out
);
    bidir_oneway#(.width($bits(in.rgb )))rgb_oneway (.in(in.rgb ),.out(out.rgb ));
    bidir_oneway#(.width($bits(in.de  )))de_oneway  (.in(in.de  ),.out(out.de  ));
    bidir_oneway#(.width($bits(in.skip)))skip_oneway(.in(in.skip),.out(out.skip));
    bidir_oneway#(.width($bits(in.vs  )))vs_oneway  (.in(in.vs  ),.out(out.vs  ));
    bidir_oneway#(.width($bits(in.hs  )))hs_oneway  (.in(in.hs  ),.out(out.hs  ));
endmodule

/*
 *   make the display 400 x 360
 *   put HS at 50, VS at (0,50)
 *   DE = (HS >= 100 & HS < 500) & (VS >= 100 && VS < 460)
 *
 *   arrange x_dots and y_dots so that
 *   x_dots * y_dots * screen_frequency = rgb_clock frequency
 */

module video_dummy#(
    parameter int x_dots = 740,
    parameter int y_dots = 500
)(
    video_if   video
);
    // counts to 4096 which should be plenty
    typedef logic [11:0] count_t;

    count_t hcount;
    count_t vcount;

    always_ff @(posedge video.rgb_clock) begin
        if(hcount == count_t'(x_dots-1)) begin
            hcount <= '0;
            if(vcount == count_t'(y_dots-1)) begin
                vcount <= '0;
            end else begin
                vcount <= vcount + 9'h1;
            end
        end else begin
            hcount <= hcount + 10'h1;
        end
    end

    pocket::rgb_t rgb_out;
    always_ff @(posedge video.rgb_clock) begin
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
