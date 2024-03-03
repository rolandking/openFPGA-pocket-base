`timescale 1ns/1ps

module video_count(
    input logic clk,
    input logic HBLANK,
    input logic VBLANK,
    input logic CE_PIXEL,

    // total clocks for the horizontal, rising HBLANK to rising HBLANK
    output logic[15:0] x_clocks,
    // total lines for the vertical, rising HBLANK reset by VBLANK
    output logic[15:0] y_lines,
    // total unblanked clock cycles
    output logic[15:0] x_unblanked,
    // total clocks on a line with CE_ENABLE high
    output logic[15:0] x_ce_enable,
    // total unblanked lines
    output logic[15:0] y_unblanked,
    // horizontal pixels unblanked
    output logic[15:0] x_pixels
);

    typedef logic[15:0] counter_t;

    counter_t x_clocks_c, x_ce_enable_c, y_lines_c, x_unblanked_c, y_unblanked_c, x_pixels_c;
    logic vblank_pos, hblank_pos;

    edge_detect#(
        .positive( '1 )
    ) vblank_edge_pos (
        .clk,
        .in   (VBLANK),
        .out  (vblank_pos)
    );

    edge_detect#(
        .positive( '1 )
    ) hblank_edge_pos (
        .clk,
        .in   (HBLANK),
        .out  (hblank_pos)
    );

    always @(posedge clk) begin
        if(vblank_pos) begin
            y_lines       <= y_lines_c;
            y_unblanked   <= y_unblanked_c;
            y_lines_c     <= '0;
            y_unblanked_c <= '0;
        end else begin
            if(hblank_pos) begin
                y_lines_c <= y_lines_c + 16'd1;
                if(~VBLANK) begin
                    y_unblanked_c <= y_unblanked_c + 16'd1;
                end
            end
        end

        if(hblank_pos) begin
            x_clocks      <= x_clocks_c;
            x_ce_enable   <= x_ce_enable_c;
            x_unblanked   <= x_unblanked_c;
            x_pixels      <= x_pixels_c;
            x_clocks_c    <= '0;
            x_ce_enable_c <= '0;
            x_unblanked_c <= '0;
            x_pixels_c    <= '0;
        end else begin
            x_clocks_c    <= x_clocks_c + 16'd1;
            if(~HBLANK) begin
                x_unblanked_c  <= x_unblanked_c + 16'd1;
                if(CE_PIXEL) begin
                    x_pixels_c <= x_pixels_c + 16'd1;
                end
            end
            if(CE_PIXEL) begin
                x_ce_enable_c <= x_ce_enable_c + 16'd1;
            end
        end
    end

endmodule
