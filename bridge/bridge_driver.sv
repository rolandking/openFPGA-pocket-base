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
 *  0xf8000010 / 14 / 18 / 1C               host parameter data
 *  0xf8000020 / 24 / 28 / 2C               host response data
 *  0xf8000030 / 14 / 18 / 1C               core parameter data
 *  0xf8000040 / 24 / 28 / 2C               core response data
 *  0xf8001000 -        core comman  d      core command status
 *  0xf8001004 -        -                   core parameter data pointer
 *  0xf8001008 -        -                   core response data pointer
 *  0xf80020xx -        slot data           slot data
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
    parameter logic [31:0] HOST_PARAMETER_ADDR = 32'hf8000010;
    parameter logic [31:0] HOST_RESPONSE_ADDR  = 32'hf8000020;
    parameter logic [31:0] CORE_PARAMETER_ADDR = 32'hf8000030;
    parameter logic [31:0] CORE_RESPONSE_ADDR  = 32'hf8000040;

    // the data returned to the bridge
    logic [31:0]        rd_data;

    // the 16 32bit registers for parameters
    logic [31:0]        host_cmd, host_cmd_status, core_cmd, core_cmd_status;
    logic [3:0][31:0]   host_cmd_params, host_cmd_response, core_cmd_params, core_cmd_response;
    logic               core_cmd_read,  core_cmd_status_write;
    logic               host_cmd_write;

    // flatten the input

    always @(posedge bridge.clk) begin
        /*
         *   The bridge reads which means only a subset of registers
         *   needs to be supported. The bridge reads
         *     - its own command status
         *     - the addresses to put and read parameters and returns
         *     - the host command response
         *     - the core command parameters
         *     - the core command
         */

        core_cmd_read        <= '0;

        if(bridge.rd) begin

            case(bridge.addr[23:0])

                24'h000000: begin
                    // status written by core, read by host
                    rd_data <= host_cmd_status;
                end

                24'h000004: begin
                    // address read by host
                    rd_data <= HOST_PARAMETER_ADDR;
                end

                24'h000008: begin
                    // address read by host
                    rd_data <= HOST_RESPONSE_ADDR;
                end

                // host_cmd_response written by core
                // read by host
                (HOST_RESPONSE_ADDR[23:0] + 4'h0): begin
                    rd_data <= host_cmd_response[3];
                end
                (HOST_RESPONSE_ADDR[23:0] + 4'h4): begin
                    rd_data <= host_cmd_response[2];
                end
                (HOST_RESPONSE_ADDR[23:0] + 4'h8): begin
                    rd_data <= host_cmd_response[1];
                end
                (HOST_RESPONSE_ADDR[23:0] + 4'hc): begin
                    rd_data <= host_cmd_response[0];
                end

                // core cmd parameters written by core
                // read by host
                (CORE_PARAMETER_ADDR[23:0] + 4'h0): begin
                    rd_data <= core_cmd_params[3];
                end
                (CORE_PARAMETER_ADDR[23:0] + 4'h4): begin
                    rd_data <= core_cmd_params[2];
                end
                (CORE_PARAMETER_ADDR[23:0] + 4'h8): begin
                    rd_data <= core_cmd_params[1];
                end
                (CORE_PARAMETER_ADDR[23:0] + 4'hc): begin
                    rd_data <= core_cmd_params[0];
                end

                // core_cmd written by core, read by host
                24'h001000: begin
                    rd_data       <= core_cmd;
                    core_cmd_read <= '1;
                end

                // core parameter address read by host
                24'h001004: begin
                    rd_data <= CORE_PARAMETER_ADDR;
                end

                // core response address read by host
                24'h001008: begin
                    rd_data <= CORE_RESPONSE_ADDR;
                end

                default: begin
                end

            endcase
        end
    end

    pocket::bridge_data_t be_wr_data;
    always_comb be_wr_data = to_be(bridge_endian_little, bridge.wr_data);

    always @(posedge bridge.clk) begin
        /*
        *   The bridge writes so only a subset of registers
        *   needs to be supported. The bridge writes
        *    - its command
        *    - host command resgisters
        *    - core response registers
        */

        core_cmd_status_write <= '0;
        host_cmd_write        <= '0;

        if(bridge.wr) begin
            case(bridge.addr[23:0])

                // host_cmd written by host
                24'h000000: begin
                    host_cmd       <= be_wr_data;
                    host_cmd_write <= '1;
                end

                // host_cmd_params written by host
                (HOST_PARAMETER_ADDR[23:0] + 4'h0): begin
                    host_cmd_params[3] <= be_wr_data;
                end
                (HOST_PARAMETER_ADDR[23:0] + 4'h4): begin
                    host_cmd_params[2] <= be_wr_data;
                end
                (HOST_PARAMETER_ADDR[23:0] + 4'h8): begin
                    host_cmd_params[1] <= be_wr_data;
                end
                (HOST_PARAMETER_ADDR[23:0] + 4'hc): begin
                    host_cmd_params[0] <= be_wr_data;
                end

                // core_cmd_response written by host
                (CORE_RESPONSE_ADDR[23:0] + 4'h0): begin
                    core_cmd_response[3] <= be_wr_data;
                end
                (CORE_RESPONSE_ADDR[23:0] + 4'h4): begin
                    core_cmd_response[2] <= be_wr_data;
                end
                (CORE_RESPONSE_ADDR[23:0] + 4'h8): begin
                    core_cmd_response[1] <= be_wr_data;
                end
                (CORE_RESPONSE_ADDR[23:0] + 4'hc): begin
                    core_cmd_response[0] <= be_wr_data;
                end

                // core_cmd_status written by host
                24'h001000: begin
                    core_cmd_status       <= be_wr_data;
                    core_cmd_status_write <= '1;
                end

                default: begin
                end

            endcase
        end
    end

    // the current command in-process
    bridge_word_t cmd_in_process;

    // the command parameters, registered to prevent
    // changes from the host. Flattened, mapped to the
    // command structure
    bridge_param_t cmd_in_process_parameters;

    typedef enum logic[1:0] {
        // no command in progress, output previous
        // OK + status
        CMD_IDLE      = 2'b00,
        // cmd presented and valid, awaiting ack
        // output 'BU' + progress
        CMD_VALID     = 2'b01,
        // command ack'ed, deassert valid and
        // output 'BU' + progress
        CMD_PROCESS   = 2'b10
    } cmd_state_e;

    cmd_state_e cmd_state = CMD_IDLE;

    always_ff @(posedge bridge.clk) begin
        case(cmd_state)
            CMD_IDLE: begin
                if(host_cmd_write && (host_cmd[31:16] == "CM")) begin
                    cmd_in_process             <= host_cmd[15:0];
                    cmd_in_process_parameters  <= host_cmd_params;
                    host_cmd_status            <= {"BU", 16'b0};
                    cmd_state                  <= CMD_VALID;
                end
            end
            CMD_VALID: begin
                if(cmd.ack) begin
                    cmd_state <= CMD_PROCESS;
                end
            end
            CMD_PROCESS: begin
                // update the progress
                host_cmd_status <= {"BU", cmd.progress};
                if(cmd.done) begin
                    cmd_state         <= CMD_IDLE;
                    host_cmd_status   <= {"OK", cmd.result};
                    host_cmd_response <= cmd.response;
                end
            end

            default: begin
            end
        endcase
    end

    always_comb begin
        cmd.valid = 1'b0;
        case(cmd_state)
            CMD_VALID: begin
                cmd.valid = 1'b1;
            end
            default: begin
            end
        endcase

    end

    // read mux
    always_comb begin
        bridge.rd_data = to_be(bridge_endian_little, rd_data);
        cmd.word       = cmd_in_process;
        cmd.param      = cmd_in_process_parameters;
    end

    // request processing
    typedef enum logic[1:0] {
        REQUEST_IDLE = 2'b00,
        REQUEST_WAIT_WRITE = 2'b01,
        REQUEST_PROCESS = 2'b10
    } req_state_e;

    req_state_e req_state = REQUEST_IDLE;

    always_ff @(posedge bridge.clk) begin

        request.done <= '0;

        case(req_state)
            // waiting for a new command
            REQUEST_IDLE: begin
                if(request.ack) begin
                    core_cmd        <= {"cm", request.word};
                    core_cmd_params <= request.param;
                    req_state       <= REQUEST_WAIT_WRITE;
                end
            end

            // wait for host to write status for the
            // first time
            // clear the command output and
            // ack
            REQUEST_WAIT_WRITE: begin
                if(core_cmd_status_write) begin
                    core_cmd    <= '0;
                    req_state   <= REQUEST_PROCESS;
                end
            end

            REQUEST_PROCESS: begin
                // we should se 'bu' or 'ok'
                case(core_cmd_status[31:16])
                    "bu": begin
                        request.progress <= core_cmd_status[15:0];
                    end

                    "ok": begin
                        request.done   <= '1;
                        request.result <= core_cmd_status[15:0];
                        req_state      <= REQUEST_IDLE;
                    end

                    default: begin
                    end
                endcase
            end

            default: begin
            end
        endcase
    end

    always_comb begin
        request.ack = '0;
        case(req_state)
            REQUEST_IDLE: begin
                // ack on the cycle we read and transition the state machine
                request.ack = request.valid && core_cmd_read;
            end

            default: begin
            end
        endcase
    end

    always_comb begin
        request.response = core_cmd_response;
    end

endmodule
