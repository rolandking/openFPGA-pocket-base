`timescale 1ns/1ps

module core_ready_to_run(
    input wire           bridge_clk,
    input wire           pll_core_locked,
    input wire           reset_n,

    core_ready_to_run_if core_ready_to_run
);

    logic done       = '0;
    logic reset_n_ff = '0;

    always_ff @(posedge bridge_clk) begin
        reset_n_ff <= reset_n;

        if (reset_n_ff && ~reset_n) begin
            done <= 0;
        end

        if(core_ready_to_run.done) begin
            done <= '1;
        end
    end

    always_comb begin
        core_ready_to_run.valid = pll_core_locked && !done && !core_ready_to_run.done;
    end

endmodule
