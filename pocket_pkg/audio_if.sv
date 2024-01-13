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
