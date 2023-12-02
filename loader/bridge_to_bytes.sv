
// take the input from bridge which is a 32 bit word and write it out 8 bits
// at a time to memory

module bridge_to_bytes (
    input logic clk, 
    input logic [31:0]  bridge_addr,
    input logic [31:0]  bridge_wr_data,
    input logic         bridge_wr,

    output logic [31:0] mem_address,
    output logic [7:0]  mem_data, 
    output logic        mem_wr
);

    logic [3:0]  enables;
    logic [31:0] cache;
    logic [31:0] address;

    always_ff @(posedge clk) begin
        if(bridge_wr) begin
            enables <= 4'b1111;
            cache   <= bridge_wr_data;
            address <= bridge_addr;
        end else begin
            enables <= {1'b0, enables[2:0]};
            cache   <= {8'hx, cache[23:0]};
            address <= address + 32'd1;
        end
    end

    always_comb begin
        mem_address = cache[7:0];
        mem_wr      = enables[0];
        mem_address = address;
    end

endmodule
