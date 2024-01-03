 interface port_ir_if;
    logic            tx;
    logic            rx;
    logic            rx_disable;

 endinterface

 `define PORT_IR_TIE_OFF(_X)  \
    always_comb begin         \
        _X.rx_disable = '1; \
        _X.tx         = '0; \
    end
