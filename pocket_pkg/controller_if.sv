`timescale 1ns/1ps

typedef struct packed {
    pocket::key_t  key;
    pocket::joy_t  joy;
    pocket::trig_t trig;
} controller_t;

module controller_connect (
    input  pocket::key_t  key,
    input  pocket::joy_t  joy,
    input  pocket::trig_t trig,

    output controller_t   controller
);

    always_comb begin
        controller      = '0;
        controller.key  = key;
        controller.joy  = joy;
        controller.trig = trig;
    end

endmodule

/*
 * map up to 2 controllers to the equivalent
 * to two DPads. If only one controller is connected,
 * use this for both.
 * Optionally convert joystick values to DPad movments
 */
module ControllerToD#(
    parameter int   NUM_CONTROLLERS = 2,
    parameter logic MAP_JOYSTICK    = 1'b1
) (
    input  controller_t  controllers[1:4],
    output pocket::key_t keys[1:NUM_CONTROLLERS],
    output logic         exists[1:NUM_CONTROLLERS]
);

    pocket::key_t key_mapped[1:NUM_CONTROLLERS];
    generate
    genvar i;
    for(i = 1 ; i <= NUM_CONTROLLERS ; i++ ) begin : gen_controller
        logic has_joystick;
        logic [1:0] joy_x_msb, joy_y_msb;
        logic has_controller;
        always_comb begin
            has_joystick = controllers[i].key.controller_type == pocket::controller_docked_analogue;
            has_controller = has_joystick ||
                (controllers[1].key.controller_type == pocket::controller_docked_no_analogue);

            joy_x_msb = controllers[i].joy.lstick_x[7:6];
            joy_y_msb = controllers[i].joy.lstick_y[7:6];

            // start by copying the values over
            keys[i] = controllers[i].key;
            if(MAP_JOYSTICK && has_joystick) begin
                keys[i].dpad_right = controllers[i].key.dpad_right || (joy_x_msb == '1);
                keys[i].dpad_left  = controllers[i].key.dpad_left  || (joy_x_msb == '0);
                keys[i].dpad_up    = controllers[i].key.dpad_up    || (joy_y_msb == '0);
                keys[i].dpad_down  = controllers[i].key.dpad_down  || (joy_y_msb == '1);
            end

            exists[i] = (i == 0) || has_controller;
        end
    end
    endgenerate

endmodule
