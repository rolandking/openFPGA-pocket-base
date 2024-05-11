`timescale 1ns/1ps

interface audio_if;

    logic mclk;
    logic adc;
    logic dac;
    logic lrck;

    function automatic tie_off;
        mclk = '0;
        dac  = '0;
        lrck = '0;
    endfunction

endinterface

module audio_connect(
    output wire mclk,
    input  wire adc,
    output wire dac,
    output wire lrck,

    audio_if    audio
);

    always_comb begin
        mclk      = audio.mclk;
        audio.adc = adc;
        dac       = audio.dac;
        lrck      = audio.lrck;
    end

endmodule

module audio_dummy(
    input wire clk_12_288_mhz,
    audio_if audio
);

    // output silence on the left and right channels
    // lrck is low for 128 mclk cycles then high for 128

    logic [7:0] counter = 8'd0;

    always @(posedge clk_12_288_mhz) begin
        counter <= counter + 8'd1;
    end

    always_comb begin
        audio.mclk = clk_12_288_mhz;
        audio.dac  = '0;
        audio.lrck = counter[7];
    end

endmodule

    module audio_standard(
        input logic              clk_12_288_mhz,
        input logic signed[15:0] sound_l,
        input logic signed[15:0] sound_r,

        audio_if                 audio
    );

    // clock is 12.288MHz
    // = 48000 * 32 * 2 * 4 == 48000 * 256
    // this is mclk, 256 cycles of mclk for one L/R pair
    // every 4 cycles of that we shift the audio data,
    // every 32 cycles of that (128) we flip l/r and every 2 (256)
    // we take new audio data

    // count 0-256 for one complete cycle,
    // bit 7 is L/R
    logic  [7:0] counter;
    logic [63:0] shifter;

    logic signed [16:0] sound_total;
    always_comb sound_total = sound_l + sound_r;

    always @(posedge clk_12_288_mhz) begin
        counter <= counter + 8'd1;

        if( counter[1:0] == '1) begin
            shifter <= {shifter[62:0], shifter[63]};
        end

        if(counter[7:0] == '1) begin
            shifter    <= {1'b0, sound_total[16:1], 15'b0, 1'b0, sound_total[16:1], 15'b0};
            shifter    <= {1'b0, sound_l, 15'b0, 1'b0, sound_r, 15'b0};
        end
    end

    always_comb begin
        audio.lrck = counter[7];
        audio.mclk = clk_12_288_mhz;
        audio.dac  = shifter[63];
    end

endmodule
