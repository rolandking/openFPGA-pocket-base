package pocket;

    typedef enum logic {
        CART_DIR_OUTPUT = 1'b1,
        CART_DIR_INPUT  = 1'b0
    } cart_direction_e;

    typedef struct packed {
        logic [7:0] red;
        logic [7:0] green;
        logic [7:0] blue;
    } rgb_t;

    typedef enum logic [3:0] {
        controller_none               = 4'd0,
        controller_builtin            = 4'd1,
        controller_docked_no_analogue = 4'd2,
        controller_docked_analogue    = 4'd3,
        controller_docked_keyboard    = 4'd4,
        controller_docked_mouse       = 4'd5
    } controller_type_t;

    /*
     *              (X)
     *          (Y)     (A)
     *              (B)
    */
    typedef struct packed {
        controller_type_t   controller_type;
        logic [11:0]        _unused;
        logic               face_start;
        logic               face_select;
        logic               trig_r3;
        logic               trig_l3;
        logic               trig_r2;
        logic               trig_l2;
        logic               trig_r1;
        logic               trig_l1;
        logic               face_y;
        logic               face_x;
        logic               face_b;
        logic               face_a;
        logic               dpad_right;
        logic               dpad_left;
        logic               dpad_down;
        logic               dpad_up;
    } key_t;

    typedef struct packed {
        logic [7:0] rstick_y;
        logic [7:0] rstick_x;
        logic [7:0] lstick_y;
        logic [7:0] lstick_x;
    } joy_t;

    typedef struct packed {
        logic [7:0] rtrig;
        logic [7:0] ltrip;
    } trig_t;

    typedef logic [31:0] bridge_addr_t;
    typedef logic [31:0] bridge_data_t;

    typedef struct {
        bridge_addr_t from_addr;
        bridge_addr_t to_addr;
    } bridge_addr_range_t;

 endpackage

 interface bridge_if(
    input wire clk
 );
    logic                 endian_little;
    pocket::bridge_addr_t addr;
    pocket::bridge_data_t wr_data;
    logic                 wr;
    pocket::bridge_data_t rd_data;
    logic                 rd;
 endinterface

 `define BRIDGE_CONNECT_MASTER_SLAVE_NO_READ(master,slave) \
    always_comb begin                                      \
        slave.addr          = master.addr;                 \
        slave.wr_data       = master.wr_data;              \
        slave.wr            = master.wr;                   \
        slave.rd            = master.wr;                   \
    end

 `define BRIDGE_CONNECT_MASTER_SLAVE_READ(master,slave)    \
    always_comb begin                                      \
        master.rd_data = slave.rd_data;                    \
    end

 `define BRIDGE_CONNECT_MASTER_SLAVE(master,slave)         \
    `BRIDGE_CONNECT_MASTER_SLAVE_NO_READ(master,slave)     \
    `BRIDGE_CONNECT_MASTER_SLAVE_READ(master,slave)

`define BRIDGE_SET_ENDIAN_LITTLE(master,little)            \
    always_comb master.endian_little = (little ? 1'b1 : 1'b0);
