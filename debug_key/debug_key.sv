// Module for Developer Debug Key provided by Analogue.
//
// The LED uses the equivalent of the GBA /RD pin as an output
// The button uses the equivalent of the AD0 pin as an input.
//
// Note: you will need to enable the cart power in your core.json for this to work.
//

interface debug_key_if;
    wire led;
    wire button;
    wire uart_tx;
    wire uart_rx;

    function automatic tie_off();
        led     = '0;
        uart_tx = '0;
    endfunction

endinterface

module debug_key(
    port_if                 port_cart_tran_bank0,
    port_if                 port_cart_tran_bank3,
    port_if                 port_cart_tran_pin31,

    debug_key_if            debug_key
);

always_comb begin
    // Enable port0 output.
    // UART TX and LED use this bank.
    port_cart_tran_bank0.dir           = pocket::DIR_OUT;
    port_cart_tran_bank0.data_out[7]   = '0;
    // 6-5 are outputs
    port_cart_tran_bank0.data_out[4]   = '0;

    // port3 and pin31 are button in and uart RX
    // so set them to input
    port_cart_tran_bank3.dir         = pocket::DIR_IN;
    port_cart_tran_pin31.dir         = pocket::DIR_IN;

    // button input on port3, inverted, the inversion means we can assign
    // without getting a bidirectional warning
    debug_key.button                 = ~port_cart_tran_bank3.data_in[0];
end

    // as these are interface elements they are bidir so just assigning
    // causes a warning. tran() them

    // outputs on port0
    // Pin 4 is LED.
    tran(port_cart_tran_bank0.data_out[5], debug_key.led                  );
    tran(port_cart_tran_bank0.data_out[6], debug_key.uart_tx              );
    // uart RX on pin31
    tran(debug_key.uart_rx               , port_cart_tran_pin31.data_in[0]);

endmodule

// connect the uart to the debug key and tie off the reset of the
// debug key pins
module debug_key_uart_connect#(
    parameter logic led = 1'b0
)(
    debug_key_if debug_key,
    uart_if      uart
);
    always_comb begin
        debug_key.uart_tx = uart.tx;
        uart.rx           = debug_key.uart_rx;
        debug_key.led     = led;
    end

endmodule
