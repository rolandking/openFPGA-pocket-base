package pocket_pkg;

    typedef enum logic {
        CART_DIR_OUTPUT = 1'b1,
        CART_DIR_INPUT  = 1'b0
    } cart_direction_e;

    typedef struct packed {
        logic [7:0] red;
        logic [7:0] green;
        logic [7:0] blue;
    } rgb_t;

endpackage
