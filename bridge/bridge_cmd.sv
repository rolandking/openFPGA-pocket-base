`timescale 1ns/1ps

function automatic logic [31:0] to_be (
    logic       is_le,
    logic[31:0] in
);

    return is_le ? {in[7:0], in[15:8], in[23:16], in[31:24]} : in;

endfunction

/*
 *  memory map
 *                      write               read
 *  0xf8000000 -        host command        host command status
 *  0xf8000004 -        -                   host parameter data pointer
 *  0xf8000008 -        -                   host response data pointer
 *  0xf8001000 -        core comman  d      core command status
 *  0xf8001004 -        -                   core parameter data pointer
 *  0xf8001008 -        -                   core response data pointer
 *  0xf80020xx -        slot data           slot data
 *  0xf8010000 / 14 / 18 / 1C               host parameter data
 *  0xf8010010 / 24 / 28 / 2C               host response data
 *  0xf8010020 / 14 / 18 / 1C               core parameter data
 *  0xf8010030 / 24 / 28 / 2C               core response data
 */

 typedef logic [15:0]  bridge_word_t;
 typedef logic [127:0] bridge_param_t;

interface bridge_driver_if;
    // the request is valid and this is the command,
    // must be held until ack
    logic          valid;
    bridge_word_t  word;
    // the parameters for the command
    bridge_param_t param;
    // request accepted
    logic          ack;

    // progress to/from the busy update
    bridge_word_t  progress;

    // pulse for done with, with the result and response structure
    logic          done;
    bridge_word_t  result;
    bridge_param_t response;

    function automatic tie_off_master();
        valid = 1'b0;
        word  = 'x;
        param = 'x;
    endfunction

    function automatic tie_off_client();
        ack      = 1'b1;
        progress = '0;
        done     = '1;
        result   = '0;
    endfunction
endinterface

/*
 * bridge_cmd relies on the fact that writes and reads to the
 * command bus are separated by many cycles. This means we can
 * register data in and response out knowing that we won't get
 * a read for enough cycles
 */
module bridge_driver(
    bridge_if           bridge,
    input logic         bridge_endian_little,
    bridge_driver_if    cmd,
    bridge_driver_if    request
);
    parameter logic [31:0] BASE_ADDRESS          = 32'hf8000000;
    parameter logic [26:0] HOST_PARAMETER_OFFSET = 32'h00010000;
    parameter logic [26:0] HOST_RESPONSE_OFFSET  = 32'h00010010;
    parameter logic [26:0] CORE_PARAMETER_OFFSET = 32'h00010020;
    parameter logic [26:0] CORE_RESPONSE_OFFSET  = 32'h00010030;

    // the data returned to the bridge
    pocket::bridge_data_t rd_data;

    // the 16 32bit registers for parameters
    logic [31:0]        host_cmd, host_cmd_status, core_cmd, core_cmd_status;
    logic [0:3][31:0]   host_cmd_params, host_cmd_response, core_cmd_params, core_cmd_response;
    logic               core_cmd_read,  core_cmd_status_write;
    logic               host_cmd_write, host_cmd_status_read;

    // reads - just take the address and put the right data on the bus
    always_ff @(posedge bridge.clk) begin
        host_cmd_status_read  <= '0;
        core_cmd_read         <= '0;

        case(bridge.addr[26:0])
            27'h0000000: begin
                rd_data              <= host_cmd_status;
                host_cmd_status_read <= bridge.rd;
            end
            27'h0000004: begin
                rd_data <= HOST_PARAMETER_OFFSET;
            end
            27'h0000008: begin
                rd_data <= HOST_RESPONSE_OFFSET;
            end
            27'h0001000: begin
                rd_data       <= core_cmd;
                core_cmd_read <= bridge.rd;
            end
            27'h0001004: begin
                rd_data <= CORE_PARAMETER_OFFSET;
            end
            27'h0001008: begin
                rd_data <= CORE_RESPONSE_OFFSET;
            end
            HOST_RESPONSE_OFFSET[26:0] + 27'h0: begin
                rd_data <= host_cmd_response[0];
            end
            HOST_RESPONSE_OFFSET[26:0] + 27'h4: begin
                rd_data <= host_cmd_response[1];
            end
            HOST_RESPONSE_OFFSET[26:0] + 27'h8: begin
                rd_data <= host_cmd_response[2];
            end
            HOST_RESPONSE_OFFSET[26:0] + 27'hc: begin
                rd_data <= host_cmd_response[3];
            end
            CORE_PARAMETER_OFFSET[26:0] + 27'h0: begin
                rd_data <= core_cmd_params[0];
            end
            CORE_PARAMETER_OFFSET[26:0] + 27'h4: begin
                rd_data <= core_cmd_params[1];
            end
            CORE_PARAMETER_OFFSET[26:0] + 27'h8: begin
                rd_data <= core_cmd_params[2];
            end
            CORE_PARAMETER_OFFSET[26:0] + 27'hc: begin
                rd_data <= core_cmd_params[3];
            end

            default: begin
                rd_data <= '1;
            end
        endcase
    end

    always_ff @(posedge bridge.clk) begin

        host_cmd_write        <= '0;
        core_cmd_status_write <= '0;

        if(bridge.wr) begin
            case(bridge.addr[26:0])
                27'h0000000: begin
                    host_cmd       <= bridge.wr_data;
                    host_cmd_write <= '1;
                end
                27'h0001000: begin
                    core_cmd_status       <= bridge.wr_data;
                    core_cmd_status_write <= '1;
                end
                HOST_PARAMETER_OFFSET[26:0] + 27'h0: begin
                    host_cmd_params[0] <= bridge.wr_data;
                end
                HOST_PARAMETER_OFFSET[26:0] + 27'h4: begin
                    host_cmd_params[1] <= bridge.wr_data;
                end
                HOST_PARAMETER_OFFSET[26:0] + 27'h8: begin
                    host_cmd_params[2] <= bridge.wr_data;
                end
                HOST_PARAMETER_OFFSET[26:0] + 27'hc: begin
                    host_cmd_params[3] <= bridge.wr_data;
                end
                CORE_RESPONSE_OFFSET[26:0] + 27'h0: begin
                    core_cmd_response[0] <= bridge.wr_data;
                end
                CORE_RESPONSE_OFFSET[26:0] + 27'h4: begin
                    core_cmd_response[1] <= bridge.wr_data;
                end
                CORE_RESPONSE_OFFSET[26:0] + 27'h8: begin
                    core_cmd_response[2] <= bridge.wr_data;
                end
                CORE_RESPONSE_OFFSET[26:0] + 27'hc: begin
                    core_cmd_response[3] <= bridge.wr_data;
                end

                default: begin
                end
            endcase
        end
    end

    // command processing
    //
    // command starts when there is a write to host_cmd and that has
    // CM + command in it. That moves to the valid state where valid is
    // asserted and BU with no progress is output.
    // when ACKed it moves to the ACKed state where BU + progress is output
    // as soon as done is asserted the final result is output and returns to
    // idle.

    typedef enum logic[1:0] {
        CMD_STATE_IDLE  = 2'b00,
        CMD_STATE_VALID = 2'b01,
        CMD_STATE_ACKED = 2'b10,
        CMD_STATE_DONE  = 2'b11
    } cmd_state_e;

    cmd_state_e cmd_state = CMD_STATE_IDLE;

    always_comb begin
        cmd.valid = '0;
        cmd.done  = '0;

        case(cmd_state)
            CMD_STATE_IDLE:begin
            end
            CMD_STATE_VALID:begin
                cmd.valid = '1;
            end
            CMD_STATE_ACKED: begin
            end
            CMD_STATE_DONE:begin
            end
            default: begin
            end
        endcase
    end

    always_ff @(posedge bridge.clk) begin

        case(cmd_state)
            CMD_STATE_IDLE: begin
                if(host_cmd_write && host_cmd[31:16] == "CM") begin
                    cmd_state       <= CMD_STATE_VALID;
                    cmd.word        <= host_cmd[15:0];
                    cmd.param       <= host_cmd_params;
                    host_cmd_status <= {"BU", 16'd0};
                end
            end

            CMD_STATE_VALID,
            CMD_STATE_ACKED:begin
                host_cmd_status <= {"BU", cmd.progress};
                if(cmd.ack) begin
                    cmd_state <= CMD_STATE_ACKED;
                end

                if(cmd.done) begin
                    host_cmd_status   <= {"OK", cmd.result};
                    host_cmd_response <= cmd.response;
                    cmd_state         <= CMD_STATE_DONE;
                end
            end

            CMD_STATE_DONE:begin
                cmd_state <= CMD_STATE_IDLE;
            end

            default: begin
            end
        endcase
    end

endmodule
