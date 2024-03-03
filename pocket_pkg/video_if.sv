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
 *   x_dots * y_dots * screen_frequency * duty = rgb_clock frequency
 */

module video_dummy#(
    // total clock cycles between hsyncs
    parameter int x_dots = 740,
    // total hsyncs between vsync - so framerate = clock_freq / x_dots / y_dots
    parameter int y_dots = 500,

    // total x_pixels shown, the number active is x_px * duty
    parameter int x_px   = 400,

    // total lines shown
    parameter int y_px   = 360,

    // number of cycles per x_px above
    parameter int duty   = 1        // how many clock cycles to one enabled pixel
)(
    video_if   video
);

    // video should be base grey (127,127,127)
    // with a 2px white line around the border,
    // a 2px blue line inside that
    // a 2px red line inside that and
    // a 2px green line inside that.
    //
    // centered should be a 64x64 color square
    // where the colour is red on x, green on y
    // and blue is the max of both of them
    //
    // put HS and VS at a count of 10

    typedef logic [11:0] count_t;

    logic pulse;
    pulse_generator#(
        .BEATS  (duty)
    ) p_gen (
        .clk    (video.rgb_clock),
        .pulse
    );

    count_t hcount;
    count_t vcount;
    count_t xcount;

    // basic dot counts
    always_ff @(posedge video.rgb_clock) begin
        if(hcount == count_t'(x_dots-1)) begin
            hcount <= '0;
            xcount <= '0;
            if(vcount == count_t'(y_dots-1)) begin
                vcount <= '0;
            end else begin
                vcount <= vcount + 9'h1;
            end
        end else begin
            hcount <= hcount + 10'h1;
            xcount <= pulse ? (xcount + 10'h1) : xcount;
        end
    end

    localparam int hs      = 10;
    localparam int vs      = 10;
    localparam int x_start = hs + 10;
    localparam int y_start = vs + 10;
    localparam int x_end   = x_start + x_px;
    localparam int y_end   = y_start + y_px;
    localparam int sq_start_x = x_start + x_px / 2 - 32;
    localparam int sq_end_x   = sq_start_x + 64;
    localparam int sq_start_y = y_start + y_px / 2 - 32;
    localparam int sq_end_y   = sq_start_y + 64;

    pocket::rgb_t square_rgb;
    logic [5:0] xoff, yoff;
    always_comb begin
        xoff = xcount - sq_start_x;
        yoff = vcount - sq_start_y;

        square_rgb       = '0;
        square_rgb.red   = xoff << 2;
        square_rgb.green = yoff << 2;
        square_rgb.blue  = (xoff > yoff) ? (xoff << 2) : (yoff << 2);
    end

    pocket::rgb_t rgb_out;
    always_comb begin
        // start with base case grey
        rgb_out = '{red:8'd127,green:8'd127,blue:8'd127};

        // if we're within 8px of either edge then green
        if((xcount < (x_start+8)) || (xcount >= (x_end - 8)) || (vcount < (y_start+8)) || (vcount >= (y_end-8))) begin
            rgb_out = '{red:8'd0, green:8'd255, blue: 8'd0};
        end
        if((xcount < (x_start+6)) || (xcount >= (x_end - 6)) || (vcount < (y_start+6)) || (vcount >= (y_end-6))) begin
            rgb_out = '{red:8'd0, green:8'd0, blue: 8'd255};
        end
        if((xcount < (x_start+4)) || (xcount >= (x_end - 4)) || (vcount < (y_start+4)) || (vcount >= (y_end-4))) begin
            rgb_out = '{red:8'd255, green:8'd0, blue: 8'd0};
        end
        if((xcount < (x_start+2)) || (xcount >= (x_end - 2)) || (vcount < (y_start+2)) || (vcount >= (y_end-2))) begin
            rgb_out = '{red:8'd255, green:8'd255, blue: 8'd255};
        end
        if((xcount >= sq_start_x) && (xcount < sq_end_x) && (vcount >= sq_start_y) && (vcount < sq_end_y)) begin
            rgb_out = square_rgb;
        end
    end

    always_comb begin
        video.hs    = hcount == hs;
        video.vs    = vcount == vs;
        video.de    = (xcount >= x_start && xcount < x_end && vcount >= y_start && vcount < y_end);
        video.skip  = ~pulse && video.de;
        video.rgb   = video.de ? rgb_out : '0;
    end

endmodule
