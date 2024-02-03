`timescale 1ns/1ps

/*
 *  when connecting up two interfaces in a known direction just doing
 *  A = B leads to a warning. This module flattens an inout into an out
 *  for connection without the warning
 *
 *  eg
 *     foo_if {
          logic [7:0] A;
        };

        bar_if {
            logic [7:0] B;
        };

        foo_if X();
        bar_if Y();

        Y.B = X.A; // warning about unidirectional connection

        logic [7:0] C;
        bidir_oneway#(
            .width(8)
        ) (
            .in  (X.A),
            .out (C)
        );

        always_comb Y.B = C; // no warning
 }
 */

module bidir_oneway#(
    parameter int width = 1
) (
    input  logic [width-1:0] in,
    output logic [width-1:0] out
);
    always_comb out = in;
endmodule
