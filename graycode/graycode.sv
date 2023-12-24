`timescale 1ns/1ps

module int_to_gray #(
    parameter int num_bits
)(
    input  wire[num_bits-1:0] int_in,
    output wire[num_bits-1:0] gray_out
);

    logic [num_bits-1:0] shifted;
    always_comb begin
        shifted  = num_bits'( int_in >> 1 );
        gray_out = int_in ^ shifted;
    end

endmodule

module gray_to_int #(
    parameter int num_bits
) (
    input  wire[num_bits-1:0] gray_in,
    output wire[num_bits-1:0] int_out
);

    always_comb begin
        int_out[num_bits-1] = gray_in[num_bits-1];
        for( int i = 0 ; i < num_bits-1 ; i++ ) begin
            int_out[num_bits-i-2] = int_out[num_bits-i-1] ^ gray_in[num_bits-i-2];
        end
    end

endmodule
