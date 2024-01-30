`timescale 1ns/1ps

module tran_bus#(
    parameter int width = 1
)(
    inout wire [width-1:0] A,
    inout wire [width-1:0] B
);

    generate
    genvar i;
        for( i = 0 ; i < width ; i++ ) begin : gen_tran
            tran(A[i], B[i]);
        end
    endgenerate

endmodule
