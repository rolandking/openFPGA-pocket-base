`timescale 1ns/1ps

interface controller_if;

    pocket::key_t  key;
    pocket::joy_t  joy;
    pocket::trig_t trig;

    function automatic connect(
        ref pocket::key_t  _key,
        ref pocket::joy_t  _joy,
        ref pocket::trig_t _trig
    );
        key  = _key;
        joy  = _joy;
        trig = _trig;

    endfunction

endinterface

module controller_connect (
    input pocket::key_t key,
    input pocket::joy_t joy,
    input pocket::trig_t trig,

    controller_if        controller
);

    always_comb begin
        controller.key  = key;
        controller.joy  = joy;
        controller.trig = trig;
    end

endmodule
