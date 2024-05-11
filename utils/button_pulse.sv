`timescale 1ns/1ps

/*
    turn a number of button inputs into pulses. When any of the buttons is
    pressed a pulse is generated. Then no more will generate until either
    the timer times out or all buttons are released and re-pressed
*/
module button_pulse #(
    parameter int                     counter_bits,
    parameter logic[counter_bits-1:0] reload = '1,
    parameter int                     num_buttons = 1
) (
    input  wire                   clk,
    input  wire[num_buttons-1:0]  buttons_in,
    output logic[num_buttons-1:0] pulse_out
);

    typedef logic[counter_bits-1:0] counter_t;
    counter_t counter = '0;

    always_ff @(posedge clk) begin
        pulse_out <= '0;
        if(|buttons_in) begin
            if(counter == '0) begin
                pulse_out <= buttons_in;
                counter   <= reload;
            end else begin
                counter <= counter - num_buttons'(1'b1);
            end
        end else begin
            counter <= '0;
        end
    end

endmodule