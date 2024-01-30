`timescale 1ns/1ps

interface host_dataslot_request_read_if;
    logic                                             valid;
    bridge_pkg::host_dataslot_request_read_param_t    param;
    logic                                             done;
    bridge_pkg::host_dataslot_request_read_result_e   result;

    function automatic void tie_off();
        done   = 1'b1;
        result = bridge_pkg::host_dataslot_request_read_result_ready_to_read;
    endfunction

endinterface

interface host_dataslot_request_write_if;
    logic                                             valid;
    bridge_pkg::host_dataslot_request_write_param_t   param;
    logic                                             done;
    bridge_pkg::host_dataslot_request_write_result_e  result;

    function automatic void tie_off();
        done   = 1'b1;
        result = bridge_pkg::host_dataslot_request_write_result_ready_to_write;
    endfunction

endinterface

interface host_dataslot_update_if;
    logic                                             valid;
    bridge_pkg::host_dataslot_update_param_t          param;

    function automatic void tie_off();
    endfunction

endinterface

interface host_dataslot_complete_if;
    logic                                             valid;
    logic                                             done;

    function automatic void tie_off();
        done = '1;
    endfunction

endinterface

interface host_rtc_update_if;
    logic                                             valid;
    bridge_pkg::host_rtc_update_param_t               param;

    function automatic void tie_off();
    endfunction

endinterface

interface host_savestate_start_query_if;
    logic                                             valid;
    bridge_pkg::host_savestate_start_query_param_t    param;
    logic                                             done;
    bridge_pkg::host_savestate_start_query_result_e   result;
    bridge_pkg::host_savestate_start_query_response_t response;

    function automatic void tie_off();
        done = '1;
        result = bridge_pkg::host_savestate_start_query_result_ok;
        response = '{created:0, address:'0, size:'0};
    endfunction

endinterface

interface host_savestate_load_query_if;
    logic                                             valid;
    bridge_pkg::host_savestate_load_query_param_t     param;
    logic                                             done;
    bridge_pkg::host_savestate_load_query_result_e    result;
    bridge_pkg::host_savestate_load_query_response_t  response;

    function automatic void tie_off();
        done = '1;
        result = bridge_pkg::host_savestate_load_query_result_ok;
        response = '{loaded:0, address:'0, max_size:'0};
    endfunction
endinterface

interface host_notify_cartridge_if;
    logic                                             valid;
    bridge_pkg::host_notify_cartridge_param_t         param;

    function automatic void tie_off();
    endfunction

endinterface

interface host_notify_display_mode_if;
    logic                                             valid;
    bridge_pkg::host_notify_display_mode_param_t      param;
    logic                                             done;
    bridge_pkg::host_notify_display_mode_response_t   response;

    function automatic void tie_off();
        done = '1;
        response = '0;  // default to not ack'ing greyscale modes
    endfunction
endinterface

interface core_ready_to_run_if;
    logic                                             valid;
    logic                                             ack;
    logic                                             done;

    function automatic void tie_off();
        valid = '0;
    endfunction
endinterface

interface core_debug_event_log_if;
    logic                                             valid;
    bridge_pkg::core_debug_event_log_param_t          param;
    logic                                             ack;
    logic                                             done;

    function automatic void tie_off();
        valid = '0;
        param = '0;
    endfunction
endinterface

interface core_dataslot_read_if;
    logic                                             valid;
    bridge_pkg::core_dataslot_read_param_t            param;
    logic                                             ack;
    logic                                             done;
    bridge_pkg::core_dataslot_read_result_e           result;

    function automatic void tie_off();
        valid = '0;
        param = '0;
    endfunction
endinterface

interface core_dataslot_write_if;
    logic                                             valid;
    bridge_pkg::core_dataslot_write_param_t           param;
    logic                                             ack;
    logic                                             done;
    bridge_pkg::core_dataslot_write_result_e          result;

    function automatic void tie_off();
        valid = '0;
        param = '0;
    endfunction
endinterface

interface core_dataslot_flush_if;
    logic                                             valid;
    bridge_pkg::core_dataslot_flush_param_t           param;
    logic                                             ack;
    logic                                             done;
    bridge_pkg::core_dataslot_flush_result_e          result;

    function automatic void tie_off();
        valid = '0;
        param = '0;
    endfunction
endinterface

interface core_get_dataslot_filename_if;
    logic                                             valid;
    bridge_pkg::core_get_dataslot_filename_param_t    param;
    logic                                             ack;
    logic                                             done;
    bridge_pkg::core_get_dataslot_filename_result_e   result;

    function automatic void tie_off();
        valid = '0;
        param = '0;
    endfunction
endinterface

interface core_open_dataslot_file_if;
    logic                                             valid;
    bridge_pkg::core_open_dataslot_file_param_t       param;
    logic                                             ack;
    logic                                             done;
    bridge_pkg::core_open_dataslot_file_result_e      result;

    function automatic void tie_off();
        valid = '0;
        param = '0;
    endfunction
endinterface

/*
 * implement the bridge commands and requests
 */
module bridge_command (
    // takes a bridge_if which covers the range 8'hf8000000 - 8'hf8001fff
    bridge_if                                       bridge,

    // host_request_status - core provides a continuous status,
    // returning undefined will hold the request
    input  bridge_pkg::host_request_status_result_e core_status,

    // turn the reset_enter and reset_exit pulses into reset_n
    // which defaults to 0
    output logic                                    reset_n = 0,

    // command related
    host_dataslot_request_read_if                   host_dataslot_request_read,
    host_dataslot_request_write_if                  host_dataslot_request_write,
    host_dataslot_update_if                         host_dataslot_update,
    host_dataslot_complete_if                       host_dataslot_complete,
    host_rtc_update_if                              host_rtc_update,
    host_savestate_start_query_if                   host_savestate_start_query,
    host_savestate_load_query_if                    host_savestate_load_query,
    output logic                                    in_menu = 0,
    host_notify_cartridge_if                        host_notify_cartridge,
    output logic                                    docked = 0,
    host_notify_display_mode_if                     host_notify_display_mode,

    core_ready_to_run_if                            core_ready_to_run,
    core_debug_event_log_if                         core_debug_event_log,
    core_dataslot_read_if                           core_dataslot_read,
    core_dataslot_write_if                          core_dataslot_write,
    core_dataslot_flush_if                          core_dataslot_flush,
    core_get_dataslot_filename_if                   core_get_dataslot_filename,
    core_open_dataslot_file_if                      core_open_dataslot_file
);

    bridge_driver_if cmd();
    bridge_driver_if request();

    bridge_driver bd (
        .bridge,
        .cmd,
        .request
    );

    ///////////////////////////////////////////////////////////////
    //
    //                     COMMANDS
    //
    ///////////////////////////////////////////////////////////////

    bridge_pkg::host_notify_docked_state_param_t host_notify_docked_state_param;
    bridge_pkg::host_notify_menu_state_param_t   host_notify_menu_state_param;

    always_comb begin
        host_dataslot_request_read.param  = bridge_pkg::host_dataslot_request_read_param_extract(
            cmd.param
        );
        host_dataslot_request_write.param = bridge_pkg::host_dataslot_request_write_param_extract(
            cmd.param
        );
        host_dataslot_update.param        = bridge_pkg::host_dataslot_update_param_extract(
            cmd.param
        );
        host_rtc_update.param             = bridge_pkg::host_rtc_update_param_extract(
            cmd.param
        );
        host_savestate_start_query.param  = bridge_pkg::host_savestate_start_query_param_extract(
            cmd.param
        );
        host_savestate_load_query.param   = bridge_pkg::host_savestate_load_query_param_extract(
            cmd.param
        );
        host_notify_cartridge.param       = bridge_pkg::host_notify_cartridge_param_extract(
            cmd.param
        );
        host_notify_display_mode.param    = bridge_pkg::host_notify_display_mode_param_extract(
            cmd.param
        );

        host_notify_menu_state_param     = bridge_pkg::host_notify_menu_state_param_extract(cmd.param);
        host_notify_docked_state_param   = bridge_pkg::host_notify_docked_state_param_extract(cmd.param);
    end

    typedef enum logic [4:0] {
        CMD_STATE_IDLE                   = 5'h0,
        CMD_STATE_REQUEST_STATUS         = 5'h1,
        CMD_STATE_DATASLOT_REQUEST_READ  = 5'h2,
        CMD_STATE_DATASLOT_REQUEST_WRITE = 5'h3,
        CMD_STATE_DATASLOT_COMPLETE      = 5'h4,
        CMD_STATE_SAVESTATE_START_QUERY  = 5'h5,
        CMD_STATE_SAVESTATE_LOAD_QUERY   = 5'h6,
        CMD_STATE_NOTIFY_DISPLAY_MODE    = 5'h7,

        // will exit, no result code needed
        CMD_STATE_EXIT                   = 5'h1f
    } cmd_state_e;

    // asserted when a held state can transition to idle
    // drives cmd.done
    // drives the state machine to CMD_STATE_IDLE
    logic exit_cmd_state;

    cmd_state_e cmd_state = CMD_STATE_IDLE;

    always_ff @(posedge bridge.clk) begin
        // process commands

        host_dataslot_request_read.valid  <= '0;
        host_dataslot_request_write.valid <= '0;
        host_dataslot_update.valid        <= '0;
        host_dataslot_complete.valid      <= '0;
        host_rtc_update.valid             <= '0;
        host_savestate_start_query.valid  <= '0;
        host_savestate_load_query.valid   <= '0;
        host_notify_cartridge.valid       <= '0;
        host_notify_display_mode.valid    <= '0;

        case(cmd_state)
            CMD_STATE_IDLE: begin
                if(cmd.valid) begin
                    case(cmd.word)

                        bridge_pkg::host_request_status: begin
                            cmd_state <= CMD_STATE_REQUEST_STATUS;
                        end

                        bridge_pkg::host_reset_enter: begin
                            reset_n   <= '0;
                            cmd_state <= CMD_STATE_EXIT;
                        end

                        bridge_pkg::host_reset_exit: begin
                            reset_n   <= '1;
                            cmd_state <= CMD_STATE_EXIT;
                        end

                        bridge_pkg::host_dataslot_request_read: begin
                            host_dataslot_request_read.valid <= '1;
                            cmd_state <= CMD_STATE_DATASLOT_REQUEST_READ;
                        end

                        bridge_pkg::host_dataslot_request_write: begin
                            host_dataslot_request_write.valid <= '1;
                            cmd_state <= CMD_STATE_DATASLOT_REQUEST_WRITE;
                        end

                        bridge_pkg::host_dataslot_update: begin
                            host_dataslot_update.valid <= '1;
                            cmd_state <= CMD_STATE_EXIT;
                        end

                        bridge_pkg::host_dataslot_complete: begin
                            host_dataslot_complete.valid <= '1;
                            cmd_state <= CMD_STATE_DATASLOT_COMPLETE;
                        end

                        bridge_pkg::host_rtc_update: begin
                            host_rtc_update.valid <= '1;
                            cmd_state <= CMD_STATE_EXIT;
                        end

                        bridge_pkg::host_savestate_start_query: begin
                            host_savestate_start_query.valid <= '1;
                            cmd_state <= CMD_STATE_SAVESTATE_START_QUERY;
                        end

                        bridge_pkg::host_savestate_load_query: begin
                            host_savestate_load_query.valid <= '1;
                            cmd_state <= CMD_STATE_SAVESTATE_LOAD_QUERY;
                        end

                        bridge_pkg::host_notify_menu_state: begin
                            in_menu   <= host_notify_menu_state_param.in_menu;
                            cmd_state <= CMD_STATE_EXIT;
                        end

                        bridge_pkg::host_notify_cartridge: begin
                            host_notify_cartridge.valid <= '1;
                            cmd_state <= CMD_STATE_EXIT;
                        end

                        bridge_pkg::host_notify_docked_state: begin
                            docked    <= host_notify_docked_state_param.docked;
                            cmd_state <= CMD_STATE_EXIT;
                        end

                        bridge_pkg::host_notify_display_mode: begin
                            host_notify_display_mode.valid <= '1;
                            cmd_state <= CMD_STATE_NOTIFY_DISPLAY_MODE;
                        end

                        default: begin
                            // need to exit the state machine, this command is
                            // unknown so just go straight to exit
                            cmd_state <= CMD_STATE_EXIT;
                        end
                    endcase
                    end
                end

            CMD_STATE_REQUEST_STATUS,
            CMD_STATE_EXIT,
            CMD_STATE_DATASLOT_REQUEST_READ,
            CMD_STATE_DATASLOT_REQUEST_WRITE,
            CMD_STATE_DATASLOT_COMPLETE,
            CMD_STATE_SAVESTATE_START_QUERY,
            CMD_STATE_SAVESTATE_LOAD_QUERY,
            CMD_STATE_NOTIFY_DISPLAY_MODE: begin
                if(exit_cmd_state) begin
                    cmd_state <= CMD_STATE_IDLE;
                end
            end

            // should never happen
            default: begin
                cmd_state <= CMD_STATE_IDLE;
            end

        endcase
    end


    always_comb begin
        // we can ack on the same cycle when idle
        cmd.ack      = '0;
        // this goes back in the result so default to zero
        cmd.result   = '0;
        // this is only read if used so 'x
        cmd.response = 'x;

        exit_cmd_state   = '0;

        case(cmd_state)

            CMD_STATE_IDLE: begin
                cmd.ack = '1;
            end

            CMD_STATE_REQUEST_STATUS: begin
                exit_cmd_state = (core_status != bridge_pkg::host_request_status_result_undefined);
                cmd.result     = core_status;
            end

            CMD_STATE_DATASLOT_REQUEST_READ: begin
                exit_cmd_state = host_dataslot_request_read.done;
                cmd.result     = host_dataslot_request_read.result;
            end

            CMD_STATE_DATASLOT_REQUEST_WRITE: begin
                exit_cmd_state = host_dataslot_request_write.done;
                cmd.result     = host_dataslot_request_write.result;
            end

            CMD_STATE_DATASLOT_COMPLETE: begin
                exit_cmd_state = host_dataslot_complete.done;
                cmd.result     = bridge_pkg::host_dataslot_complete_result_ok;
            end

            CMD_STATE_SAVESTATE_START_QUERY: begin
                exit_cmd_state = host_savestate_start_query.done;
                cmd.result     = host_savestate_start_query.result;
                cmd.response   = bridge_pkg::host_savestate_start_query_response_expand(
                    host_savestate_start_query.response
                );
            end

            CMD_STATE_SAVESTATE_LOAD_QUERY: begin
                exit_cmd_state   = host_savestate_load_query.done;
                cmd.result       = host_savestate_load_query.result;
                cmd.response     = bridge_pkg::host_savestate_load_query_response_expand(
                    host_savestate_load_query.response
                );
            end

            CMD_STATE_NOTIFY_DISPLAY_MODE: begin
                exit_cmd_state   = host_notify_display_mode.done;
                cmd.response = bridge_pkg::host_notify_display_mode_response_expand(
                    host_notify_display_mode.response
                );
            end

            CMD_STATE_EXIT: begin
                exit_cmd_state = '1;
            end

            default: begin
            end
        endcase
    end

    always_comb begin
        cmd.done = exit_cmd_state;
    end

    ///////////////////////////////////////////////////////////////
    //
    //                     REQUESTS
    //
    ///////////////////////////////////////////////////////////////

    // start in IDLE state, when one of the requests, in priority,
    // is asserted move to that state. Wait for request read and the
    // response to be written before checking for ok.
    // state
    typedef enum logic[3:0] {
        REQ_STATE_IDLE                  = 4'd0,
        REQ_STATE_READY_TO_RUN          = 4'd1,
        REQ_STATE_DEBUG_EVENT_LOG       = 4'd2,
        REQ_STATE_DATASLOT_READ         = 4'd3,
        REQ_STATE_DATASLOT_WRITE        = 4'd4,
        REQ_STATE_DATASLOT_FLUSH        = 4'd5,
        REQ_STATE_GET_DATASLOT_FILENAME = 4'd6,
        REQ_STATE_OPEN_DATASLOT_FILE    = 4'd7
    } req_state_e;

    // calculate the priority state
    req_state_e priority_state;
    always_comb begin
        priority_state = REQ_STATE_IDLE;
        if(core_open_dataslot_file.valid) begin
            priority_state = REQ_STATE_OPEN_DATASLOT_FILE;
        end
        if(core_get_dataslot_filename.valid) begin
            priority_state = REQ_STATE_GET_DATASLOT_FILENAME;
        end
        if(core_dataslot_flush.valid) begin
            priority_state = REQ_STATE_DATASLOT_FLUSH;
        end
        if(core_dataslot_write.valid) begin
            priority_state = REQ_STATE_DATASLOT_WRITE;
        end
        if(core_dataslot_read.valid) begin
            priority_state = REQ_STATE_DATASLOT_READ;
        end
        if(core_debug_event_log.valid) begin
            priority_state = REQ_STATE_DEBUG_EVENT_LOG;
        end
        if(core_ready_to_run.valid) begin
            priority_state = REQ_STATE_READY_TO_RUN;
        end
    end

    logic acked = '0;
    req_state_e req_state = REQ_STATE_IDLE;

    always_ff @(posedge bridge.clk) begin
        if(req_state == REQ_STATE_IDLE) begin
            req_state <= priority_state;
        end else begin
            acked <= acked | request.ack;
            if(request.done) begin
                acked     <= 0;
                req_state <= REQ_STATE_IDLE;
            end else begin
                acked <= acked | request.ack;
            end
        end
    end

    always_comb begin
        request.valid    = (req_state != REQ_STATE_IDLE) && !acked;
        request.response = '0;
    end

    always_comb begin
        request.word                    = '0;
        request.param                   = '0;

        core_ready_to_run.ack           = '0;
        core_ready_to_run.done          = '0;
        core_debug_event_log.ack        = '0;
        core_debug_event_log.done       = '0;
        core_dataslot_read.ack          = '0;
        core_dataslot_read.done         = '0;
        core_dataslot_write.ack         = '0;
        core_dataslot_write.done        = '0;
        core_dataslot_flush.ack         = '0;
        core_dataslot_flush.done        = '0;
        core_get_dataslot_filename.ack  = '0;
        core_get_dataslot_filename.done = '0;
        core_open_dataslot_file.ack     = '0;
        core_open_dataslot_file.done    = '0;

        case(req_state)

            REQ_STATE_IDLE: begin
            end
            REQ_STATE_READY_TO_RUN: begin
                request.word           = bridge_pkg::core_ready_to_run;
                core_ready_to_run.ack  = request.ack;
                core_ready_to_run.done = request.done;
            end
            REQ_STATE_DEBUG_EVENT_LOG: begin
                request.word  = bridge_pkg::core_debug_event_log;
                request.param = bridge_pkg::core_debug_event_log_param_expand(
                    core_debug_event_log.param
                );
                core_debug_event_log.ack  = request.ack;
                core_debug_event_log.done = request.done;
            end
            REQ_STATE_DATASLOT_READ: begin
                request.word  = bridge_pkg::core_dataslot_read;
                request.param = bridge_pkg::core_dataslot_read_param_expand(
                    core_dataslot_read.param
                );
                core_dataslot_read.ack  = request.ack;
                core_dataslot_read.done = request.done;
            end
            REQ_STATE_DATASLOT_WRITE: begin
                request.word  = bridge_pkg::core_dataslot_write;
                request.param = bridge_pkg::core_dataslot_write_param_expand(
                    core_dataslot_write.param
                );
                core_dataslot_write.ack  = request.ack;
                core_dataslot_write.done = request.done;
            end
            REQ_STATE_DATASLOT_FLUSH: begin
                request.word  = bridge_pkg::core_dataslot_flush;
                request.param = bridge_pkg::core_dataslot_flush_param_expand(
                    core_dataslot_flush.param
                );
                core_dataslot_flush.ack  = request.ack;
                core_dataslot_flush.done = request.done;
            end
            REQ_STATE_GET_DATASLOT_FILENAME: begin
                request.word  = bridge_pkg::core_get_dataslot_filename;
                request.param = bridge_pkg::core_get_dataslot_filename_param_expand(
                    core_get_dataslot_filename.param
                );
                core_get_dataslot_filename.ack  = request.ack;
                core_get_dataslot_filename.done = request.done;
            end
            REQ_STATE_OPEN_DATASLOT_FILE: begin
                request.word  = bridge_pkg::core_open_dataslot_file;
                request.param = bridge_pkg::core_open_dataslot_file_param_expand(
                    core_open_dataslot_file.param
                );
                core_open_dataslot_file.ack  = request.ack;
                core_open_dataslot_file.done = request.done;
            end

            default: begin
            end
        endcase
    end

    always_comb begin
        // none of the requests have a reponse send back by the host
        request.response = '0;
    end

endmodule
