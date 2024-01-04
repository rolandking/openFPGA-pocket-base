 interface port_ir_if;

    logic            tx;
    logic            rx;
    logic            rx_disable;

    // connect to top-level logic
    function automatic connect(ref logic _tx, ref logic _rx, ref logic _rx_disable);
        _tx = tx;
        _rx_disable = rx_disable;
        rx = _rx;
    endfunction

    // not using the IR port, so turn off both the LED, and
    // disable the receive circuit to save power
    function automatic tie_off();
        rx_disable = '1;
        tx         = '0;
    endfunction

 endinterface
