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

interface bridge_driver_if(
    input wire clk
);
    // the request is valid and this is the command,
    logic          valid;
    bridge_word_t  word;
    // the parameters for the command
    bridge_param_t param;

    // progress to/from the busy update
    bridge_word_t  progress;

    // pulse for done with, with the result and response structure
    logic          done;
    bridge_word_t  result;
    bridge_param_t response;

    function automatic tie_off_req();
        valid = 1'b0;
        word  = 'x;
        param = 'x;
    endfunction

    function automatic tie_off_cmd();
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
    bridge_driver_if    req
);
    // the RESPONSE and PARAMETER offsets, despite the documentation
    // seem to be offsets from the host and core command register at
    // 0xf8000000 and 0xf8001000 and not absolute addresses anywhere
    // in bridge space

    // base for host and core data
    parameter logic [31:0] HOST_BASE                = 32'hf8000000;
    parameter logic [31:0] CORE_BASE                = 32'hf8001000;

    // offset of the parameter and response from the CMD / CMD location
    parameter logic [31:0] PARAMETER_OFFSET         = 32'h00000020;
    parameter logic [31:0] RESPONSE_OFFSET          = 32'h00000040;

    // offset of the command register
    parameter logic [26:0] REG_CMD_OFFSET           = 27'h00000000;

    // offset of the parameter and response offsets
    parameter logic [26:0] REG_PARAMETER_PTR_OFFSET = 27'h00000004;
    parameter logic [26:0] REG_RESPONSE_PTR_OFFSET  = 27'h00000008;

    // offsets for the 128 bit parameter and response chunks
    parameter logic [26:0] OFFSET_0                 = 27'h00000000;
    parameter logic [26:0] OFFSET_1                 = 27'h00000004;
    parameter logic [26:0] OFFSET_2                 = 27'h00000008;
    parameter logic [26:0] OFFSET_3                 = 27'h0000000c;


    // the data returned to the bridge
    pocket::bridge_data_t rd_data;

    // the 16 32bit registers for parameters
    logic [31:0]        host_cmd, host_cmd_status, core_cmd, core_cmd_status;
    logic [0:3][31:0]   host_cmd_param, host_cmd_response, core_cmd_param, core_cmd_response;
    logic               core_cmd_read,  core_cmd_status_write;
    logic               host_cmd_write, host_cmd_status_read;

    always_comb bridge.rd_data = rd_data;

    // reads - just take the address and put the right data on the bus
    always_ff @(posedge bridge.clk) begin
        host_cmd_status_read  <= '0;
        core_cmd_read         <= '0;

        case(bridge.addr[26:0])
            HOST_BASE[26:0] + REG_CMD_OFFSET: begin
                rd_data              <= host_cmd_status;
                host_cmd_status_read <= bridge.rd;
            end
            HOST_BASE[26:0] + REG_PARAMETER_PTR_OFFSET: begin
                rd_data <= PARAMETER_OFFSET;
            end
            HOST_BASE[26:0] + REG_RESPONSE_PTR_OFFSET: begin
                rd_data <= RESPONSE_OFFSET;
            end
            CORE_BASE[26:0] + REG_CMD_OFFSET: begin
                rd_data       <= core_cmd;
                core_cmd_read <= bridge.rd;
            end
            CORE_BASE[26:0] + REG_PARAMETER_PTR_OFFSET: begin
                rd_data <= PARAMETER_OFFSET;
            end
            CORE_BASE[26:0] + REG_RESPONSE_PTR_OFFSET: begin
                rd_data <= RESPONSE_OFFSET;
            end
            HOST_BASE[26:0] + RESPONSE_OFFSET[26:0]  + OFFSET_0: begin
                rd_data <= host_cmd_response[0];
            end
            HOST_BASE[26:0] + RESPONSE_OFFSET[26:0]  + OFFSET_1: begin
                rd_data <= host_cmd_response[1];
            end
            HOST_BASE[26:0] + RESPONSE_OFFSET[26:0]  + OFFSET_2: begin
                rd_data <= host_cmd_response[2];
            end
            HOST_BASE[26:0] + RESPONSE_OFFSET[26:0]  + OFFSET_3: begin
                rd_data <= host_cmd_response[3];
            end
            CORE_BASE[26:0] + PARAMETER_OFFSET[26:0] + OFFSET_0: begin
                rd_data <= core_cmd_param[0];
            end
            CORE_BASE[26:0] + PARAMETER_OFFSET[26:0] + OFFSET_1: begin
                rd_data <= core_cmd_param[1];
            end
            CORE_BASE[26:0] + PARAMETER_OFFSET[26:0] + OFFSET_2: begin
                rd_data <= core_cmd_param[2];
            end
            CORE_BASE[26:0] + PARAMETER_OFFSET[26:0] + OFFSET_3: begin
                rd_data <= core_cmd_param[3];
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
                HOST_BASE[26:0] + REG_CMD_OFFSET: begin
                    host_cmd       <= bridge.wr_data;
                    host_cmd_write <= '1;
                end
                CORE_BASE[26:0] + REG_CMD_OFFSET: begin
                    core_cmd_status       <= bridge.wr_data;
                    core_cmd_status_write <= '1;
                end
                HOST_BASE[26:0] + PARAMETER_OFFSET[26:0] + OFFSET_0: begin
                    host_cmd_param[0] <= bridge.wr_data;
                end
                HOST_BASE[26:0] + PARAMETER_OFFSET[26:0] + OFFSET_1: begin
                    host_cmd_param[1] <= bridge.wr_data;
                end
                HOST_BASE[26:0] + PARAMETER_OFFSET[26:0] + OFFSET_2: begin
                    host_cmd_param[2] <= bridge.wr_data;
                end
                HOST_BASE[26:0] + PARAMETER_OFFSET[26:0] + OFFSET_3: begin
                    host_cmd_param[3] <= bridge.wr_data;
                end
                CORE_BASE[26:0] + RESPONSE_OFFSET[26:0]  + OFFSET_0: begin
                    core_cmd_response[0] <= bridge.wr_data;
                end
                CORE_BASE[26:0] + RESPONSE_OFFSET[26:0]  + OFFSET_1: begin
                    core_cmd_response[1] <= bridge.wr_data;
                end
                CORE_BASE[26:0] + RESPONSE_OFFSET[26:0]  + OFFSET_2: begin
                    core_cmd_response[2] <= bridge.wr_data;
                end
                CORE_BASE[26:0] + RESPONSE_OFFSET[26:0]  + OFFSET_3: begin
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
    // CM + command in it.
    // valid is asserted with progress being updated from the BU signals
    // until OK is seen, the result and response are registered and done
    // is pulsed

    typedef enum logic[1:0] {
        CMD_STATE_IDLE  = 2'b00,
        CMD_STATE_VALID = 2'b01,
        CMD_STATE_DONE  = 2'b10
    } cmd_state_e;

    cmd_state_e cmd_state = CMD_STATE_IDLE;

    always_comb begin
        cmd.valid = '0;

        case(cmd_state)
            CMD_STATE_IDLE:begin
            end
            CMD_STATE_VALID:begin
                cmd.valid = '1;
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
                    cmd.param       <= host_cmd_param;
                    host_cmd_status <= {"BU", 16'd0};
                end
            end

            CMD_STATE_VALID: begin
                if(cmd.done) begin
                    host_cmd_status   <= {"OK", cmd.result};
                    host_cmd_response <= cmd.response;
                    cmd_state         <= CMD_STATE_DONE;
                end else begin
                    host_cmd_status <= {"BU", cmd.progress};
                end
            end

            CMD_STATE_DONE:begin
                cmd_state <= CMD_STATE_IDLE;
            end

            default: begin
            end
        endcase
    end

    // request
    // if idle accept a valid request and ack it, put it onto the bus
    // wait for the next read of the request then remove it and transition to processing
    // each cycle update the progress on a 'bu' and if 'ok' send done with the answer

    typedef enum logic[1:0] {
        REQ_STATE_IDLE              = 2'b00,
        REQ_STATE_WAIT_WRITE_STATUS = 2'b01,
        REQ_STATE_WAIT_DONE         = 2'b10,
        REQ_STATE_DONE              = 2'b11
    } req_state_t;

    req_state_t req_state;

    always_comb begin
        req.done = '0;

        case(req_state)
            REQ_STATE_IDLE: begin
            end
            REQ_STATE_WAIT_WRITE_STATUS: begin
            end
            REQ_STATE_WAIT_DONE: begin
            end
            REQ_STATE_DONE: begin
                req.done = '1;
            end
            default: begin
            end
        endcase
    end

    always_ff @(posedge bridge.clk) begin
        case(req_state)
            REQ_STATE_IDLE: begin
                if(req.valid) begin
                    core_cmd        <= {"cm", req.word};
                    core_cmd_param  <= req.param;
                    req_state <= REQ_STATE_WAIT_WRITE_STATUS;
                end
            end

            REQ_STATE_WAIT_WRITE_STATUS: begin
                if(core_cmd_status_write) begin
                    core_cmd <= '0;
                    req_state <= REQ_STATE_WAIT_DONE;
                end
            end

            REQ_STATE_WAIT_DONE: begin
                if(core_cmd_status[31:16] == "bu") begin
                    req.progress <= core_cmd_status[15:0];
                end

                if(core_cmd_status[31:16] == "ok") begin
                    req.progress <= core_cmd_status[15:0];
                    req.response <= core_cmd_response;
                    req_state        <= REQ_STATE_DONE;
                end
            end

            REQ_STATE_DONE: begin
                req_state <= REQ_STATE_IDLE;
            end

            default: begin
            end
        endcase
    end

endmodule
