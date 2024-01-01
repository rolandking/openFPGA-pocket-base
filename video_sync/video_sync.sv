`timescale 1ns/1ps

/*
 *  Video output generator.
 *
 *  The module runs at clk frequency outputing to the video subsystem.
 *  MULTIPLIER can be set to an integer number of clocks where there is
 *  an enable pulse every MULTIPLIER clocks. Only when enable is asserted
 *  do the counters move forward and a pixel is output.
 *
 *  X_PRE and Y_PRE allow you to generate the x_index, y_index and
 *  corresponding valid signals a number of cycles before the pixel value
 *  is required.
 *
 *  with X_PRE / Y_PRE == 0 the rgb_in must be combinatorial on the same
 *  cycle that the values change. For memory lookups set X_PRE/Y_PRE to
 *  1 or 2
 *
 *  output counters, enables etc are valid for the entire period to the next
 *  en input
 *
 *  dotclock must be X_TOTAL * Y_TOTAL * MULTIPLIER
*/

`include "../svh/assert.svh"

module video_sync #(
parameter int VISIBLE_WIDTH   = 400,
parameter int VISIBLE_HEIGHT  = 360,
parameter int TOTAL_WIDTH     = 500,
parameter int TOTAL_HEIGHT    = 400,
parameter int FRAME_FREQUENCY = 50,
parameter int DOT_CLOCK       = 0,
parameter int X_PRE           = 0,              // start the x count X_PRE pixels before DE
parameter int Y_PRE           = 0,              // start the y count Y_PRE lines before a valid line
parameter int MULTIPLIER      = 1,              // number of clock cycles per enable

parameter int x_index_width    = $clog2(VISIBLE_HEIGHT),
parameter int y_index_width    = $clog2(VISIBLE_WIDTH),
parameter int row_index_width  = $clog2(TOTAL_HEIGHT),
parameter int col_index_width  = $clog2(TOTAL_WIDTH)
) (

    input  wire                         clk,               // should be of DOT_CLOCK frequency
    input  wire                         en,                // clock enable

    // outputs for the pocket video system
    output logic                        vs,                // VS is also the start of the first line
    output logic                        hs,                // offset from the start of the line
    output logic                        de,                // enabled for the entire visible line
    output logic                        skip,              // true if the pixel should be skipped
    output pocket::rgb_t                rgb,               // rgb output

    // outputs to drive video logic
    output logic                        line_start,        // pulse at the start of each line, before HS
    output logic[y_index_width-1:0]     y_index,
    output logic                        y_index_valid,     // y_index is valid, this can be offset by Y_PRE from actual counts
    output logic[x_index_width-1:0]     x_index,           // x_index of the dot, may be offset by X_PRE
    output logic                        x_index_valid,     // true when the x_index is valid

    input  pocket::rgb_t                rgb_in             // input rgb, the module will deal with blanking it for you
);

    typedef logic[x_index_width-1:0]    x_index_t;
    typedef logic[y_index_width-1:0]    y_index_t;
    typedef logic[row_index_width-1:0]  row_index_t;
    typedef logic[col_index_width-1:0]  col_index_t;

    // single cycle pulses are generated when the row / column == something
    localparam row_index_t VS_ROW           = row_index_t'(0);
    localparam col_index_t VS_COL           = col_index_t'(0);
    localparam col_index_t HS_COL           = col_index_t'(4);

    // on-cycle combo signals
    localparam row_index_t SCREEN_LAST_ROW  = row_index_t'(TOTAL_HEIGHT - 1);
    localparam col_index_t SCREEN_LAST_COL  = col_index_t'(TOTAL_WIDTH  - 1);

    // registered signals work on the clock previous
    localparam row_index_t DE_FIRST_ROW_PRE = row_index_t'(TOTAL_HEIGHT - VISIBLE_HEIGHT - 2);
    localparam row_index_t DE_LAST_ROW_PRE  = row_index_t'(TOTAL_HEIGHT - 2);
    localparam col_index_t DE_FIRST_COL_PRE = col_index_t'(TOTAL_WIDTH  - VISIBLE_WIDTH  - 2);
    localparam col_index_t DE_LAST_COL_PRE  = col_index_t'(TOTAL_WIDTH  - 2);

    localparam row_index_t Y_FIRST_ROW_PRE  = row_index_t'(DE_FIRST_ROW_PRE - X_PRE);
    localparam row_index_t Y_LAST_ROW_PRE   = row_index_t'(DE_LAST_ROW_PRE  - X_PRE);
    localparam col_index_t X_FIRST_COL_PRE  = col_index_t'(DE_FIRST_COL_PRE - Y_PRE);
    localparam col_index_t X_LAST_COL_PRE   = col_index_t'(DE_LAST_COL_PRE  - Y_PRE);

    localparam int         EXPECTED_CLOCK   = (TOTAL_WIDTH * TOTAL_HEIGHT * FRAME_FREQUENCY * MULTIPLIER);

    `STATIC_ASSERT(TOTAL_HEIGHT >= (VISIBLE_HEIGHT+2+Y_PRE), TOTAL_HEIGHT too small for VISIBLE_HEIGHT)
    `STATIC_ASSERT(TOTAL_WIDTH  >= (VISIBLE_WIDTH+2+X_PRE ), TOTAL_WIDTH too small for VISIBLE_WIDTH)
    `STATIC_ASSERT(DE_FIRST_COL_PRE > HS_COL, DE would occur before or too soon after HS)
    `STATIC_ASSERT(EXPECTED_CLOCK == DOT_CLOCK, Check the DOT_CLOCK Frequency )

    // our current counters
    row_index_t current_row = '0;
    col_index_t current_col = '0;

    always_ff @(posedge clk) begin
        if(en) begin
            line_start <= '0;
            if(current_col == SCREEN_LAST_COL) begin
                current_col <= '0;
                line_start  <= '1;
                if(current_row == SCREEN_LAST_ROW) begin
                    current_row <= '0;
                end else begin
                    current_row <= (current_row + row_index_t'(1'b1));
                end
            end else begin
                current_col <= (current_col + col_index_t'(1'b1));
            end
        end
    end

    logic de_row;
    always_ff @(posedge clk) begin
        if(en) begin
            case (current_row)
                DE_FIRST_ROW_PRE: begin
                    de_row <= '1;
                end
                DE_LAST_ROW_PRE: begin
                    de_row <= '0;
                end

                default: begin
                end
            endcase
        end
    end

    logic de_col;
    always_ff @(posedge clk) begin
        if(en) begin
            case (current_col)
                DE_FIRST_COL_PRE: begin
                    de_col <= '1;
                end
                DE_LAST_COL_PRE: begin
                    de_col <= '0;
                end

                default: begin
                end
            endcase
        end
    end

    always @(posedge clk) begin
        if(en) begin
            if(current_col == SCREEN_LAST_COL) begin
                y_index <= y_index_valid ? (y_index + y_index_t'(1'b1) ) : '0;
                case (current_row)
                    Y_FIRST_ROW_PRE: begin
                        y_index_valid <= '1;
                    end
                    Y_LAST_ROW_PRE: begin
                        y_index_valid <= '0;
                    end

                    default: begin
                    end
                endcase
            end
        end
    end

    always @(posedge clk) begin
        if(en) begin
            x_index <= x_index_valid ? (x_index + x_index_t'(1'b1) ) : '0;
            case (current_col)
                X_FIRST_COL_PRE: begin
                    x_index_valid <= '1;
                end

                X_LAST_COL_PRE: begin
                    x_index_valid <= '0;
                end

                default: begin
                end
            endcase
        end
    end

    always_comb begin
        vs  = (current_row == VS_ROW) && (current_col == VS_COL) && en;
        hs  = (current_col == HS_COL) && en;
        de  = de_row && de_col;
        // TODO: add the flags and mode switch here
        rgb = de ? rgb_in : pocket::rgb_t'('0);
        skip = de && ~en;
    end

endmodule
