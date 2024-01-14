 interface ir_if;

    wire tx;
    wire rx;
    wire rx_disable;

    // not using the IR port, so turn off both the LED, and
    // disable the receive circuit to save power
    function automatic tie_off();
        rx_disable = '1;
        tx         = '0;
    endfunction

 endinterface

 module ir_connect(
    output wire tx,
    output wire rx_disable,
    input  wire rx,

    ir_if       ir
 );

    always_comb begin
        tx         = ir.tx;
        rx_disable = ir.rx_disable;
        ir.rx      = rx;
    end

 endmodule
