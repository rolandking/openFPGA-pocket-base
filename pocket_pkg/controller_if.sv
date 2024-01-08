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
