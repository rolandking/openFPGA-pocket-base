`timescale 1ns/1ps

interface audio_if;
    logic mclk;
    logic adc;
    logic dac;
    logic lrck;

    function automatic connect(
        ref logic _mclk,
        ref logic _adc,
        ref logic _dac,
        ref logic _lrck
    );
        _mclk = mclk;
        adc   = _adc;
        _dac  = dac;
        _lrck = lrck;
    endfunction

    function automatic tie_off;
        mclk = '0;
        dac  = '0;
        lrck = '0;
    endfunction

endinterface

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
