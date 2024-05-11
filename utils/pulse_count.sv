`timescale 1ns/1ps

module pulse_count #(
    parameter int num_states
) (
    input  wire                          clk,
    input  wire                          up_pulse,
    input  wire                          down_pulse,
    output logic [$clog2(num_states)-1:0] count = 0
);

    typedef logic [$clog2(num_states)-1:0] count_t;

    count_t next_up;
    count_t next_down;

    always_comb begin
        next_up   = (count == num_states-1) ? '0                         : count + count_t'(1'b1);
        next_down = (count == '0         ) ? num_states - count_t'(1'b1) : count - count_t'(1'b1);
    end

    always_ff @(posedge clk) begin
        case({up_pulse, down_pulse})
            2'b00, 2'b11: begin
            end
            2'b10 : begin
                count <= next_up;
            end
            2'b01 : begin
                count <= next_down;
            end
            default: begin
            end
        endcase
    end

endmodule
