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
    //                                                no result
    bridge_pkg::host_notify_display_mode_response_t   response;

    function automatic void tie_off();
        done = '1;
        response = '0;  // default to not ack'ing greyscale modes
    endfunction
endinterface

/*
 * implement the bridge commands
 */
module bridge_cmd (
    bridge_driver_if                                cmd,

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
    host_notify_display_mode_if                     host_notify_display_mode
);

    // not exported in this form
    bridge_pkg::host_notify_docked_state_param_t host_notify_docked_state_param;
    bridge_pkg::host_notify_menu_state_param_t   host_notify_menu_state_param;

    // flatten cmd.param into a one-way signal so we can use it in always_comb
    // below to expand the params. Just connecting them gives lots of bidirectional
    // port assigned unidirectionally errors
    bridge_param_t param;
    bidir_oneway#(
        .width($bits(bridge_param_t))
    ) param_flat(
        .in      (cmd.param),
        .out     (param)
    );

    always_comb begin
        host_dataslot_request_read.param  = bridge_pkg::host_dataslot_request_read_param_extract(
            param
        );
        host_dataslot_request_write.param = bridge_pkg::host_dataslot_request_write_param_extract(
            param
        );
        host_dataslot_update.param        = bridge_pkg::host_dataslot_update_param_extract(
            param
        );
        host_rtc_update.param             = bridge_pkg::host_rtc_update_param_extract(
            param
        );
        host_savestate_start_query.param  = bridge_pkg::host_savestate_start_query_param_extract(
            param
        );
        host_savestate_load_query.param   = bridge_pkg::host_savestate_load_query_param_extract(
            param
        );
        host_notify_cartridge.param       = bridge_pkg::host_notify_cartridge_param_extract(
            param
        );
        host_notify_display_mode.param    = bridge_pkg::host_notify_display_mode_param_extract(
            param
        );

        host_notify_menu_state_param      = bridge_pkg::host_notify_menu_state_param_extract(cmd.param);
        host_notify_docked_state_param    = bridge_pkg::host_notify_docked_state_param_extract(cmd.param);
    end

    // one state per type, entering the state sets up the cmd and
    // parameters, exiting the state sends the response

    typedef enum logic [3:0] {
        CMD_STATE_IDLE                     = 4'd0,
        CMD_STATE_REQUEST_STATUS           = 4'd1,
        CMD_STATE_RESET_ENTER              = 4'd2,
        CMD_STATE_RESET_EXIT               = 4'd3,
        CMD_STATE_DATASLOT_REQUEST_READ    = 4'd4,
        CMD_STATE_DATASLOT_REQUEST_WRITE   = 4'd5,
        CMD_STATE_DATASLOT_UPDATE          = 4'd6,
        CMD_STATE_DATASLOT_COMPLETE        = 4'd7,
        CMD_STATE_RTC_UPDATE               = 4'd8,
        CMD_STATE_SAVESTATE_START_QUERY    = 4'd9,
        CMD_STATE_SAVESTATE_LOAD_QUERY     = 4'd10,
        CMD_STATE_HOST_NOTIFY_MENU_STATE   = 4'd11,
        CMD_STATE_HOST_NOTIFY_CARTRIDGE    = 4'd12,
        CMD_STATE_HOST_NOTIFY_DOCKED_STATE = 4'd13,
        CMD_STATE_NOTIFY_DISPLAY_MODE      = 4'd14,
        CMD_STATE_FORCE_EXIT               = 4'd15
    } cmd_state_e;

    cmd_state_e cmd_state = CMD_STATE_IDLE;

    always_ff @(posedge cmd.clk) begin
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

        if(cmd_state == CMD_STATE_IDLE) begin
            if(cmd.valid) begin
                case(cmd.word)

                    bridge_pkg::host_request_status: begin
                        cmd_state <= CMD_STATE_REQUEST_STATUS;
                    end

                    bridge_pkg::host_reset_enter: begin
                        reset_n   <= '0;
                        cmd_state <= CMD_STATE_RESET_ENTER;
                    end

                    bridge_pkg::host_reset_exit: begin
                        reset_n   <= '1;
                        cmd_state <= CMD_STATE_RESET_EXIT;
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
                        cmd_state <= CMD_STATE_DATASLOT_UPDATE;
                    end

                    bridge_pkg::host_dataslot_complete: begin
                        host_dataslot_complete.valid <= '1;
                        cmd_state <= CMD_STATE_DATASLOT_COMPLETE;
                    end

                    bridge_pkg::host_rtc_update: begin
                        host_rtc_update.valid <= '1;
                        cmd_state <= CMD_STATE_RTC_UPDATE;
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
                        cmd_state <= CMD_STATE_HOST_NOTIFY_MENU_STATE;
                    end

                    bridge_pkg::host_notify_cartridge: begin
                        host_notify_cartridge.valid <= '1;
                        cmd_state <= CMD_STATE_HOST_NOTIFY_CARTRIDGE;
                    end

                    bridge_pkg::host_notify_docked_state: begin
                        docked    <= host_notify_docked_state_param.docked;
                        cmd_state <= CMD_STATE_HOST_NOTIFY_DOCKED_STATE;
                    end

                    bridge_pkg::host_notify_display_mode: begin
                        host_notify_display_mode.valid <= '1;
                        cmd_state <= CMD_STATE_NOTIFY_DISPLAY_MODE;
                    end

                    default: begin
                        // need to exit the state machine, this command is
                        // unknown so force an exit
                        cmd_state <= CMD_STATE_FORCE_EXIT;
                    end
                endcase
            end
        end else begin
            if(cmd.done) begin
                cmd_state <= CMD_STATE_IDLE;
            end
        end
    end

    always_comb begin
        // this goes back in the result so default to zero
        cmd.result   = '0;
        // this is only read if used so 'x
        cmd.response = 'x;

        // also pushes the state machine to exit
        cmd.done     = '0;

        case(cmd_state)

            CMD_STATE_IDLE: begin
            end

            CMD_STATE_REQUEST_STATUS: begin
                cmd.done   = (core_status != bridge_pkg::host_request_status_result_undefined);
                cmd.result = core_status;
            end

            CMD_STATE_RESET_EXIT: begin
                cmd.done = '1;
            end

            CMD_STATE_DATASLOT_REQUEST_READ: begin
                cmd.done   = host_dataslot_request_read.done;
                cmd.result = host_dataslot_request_read.result;
            end

            CMD_STATE_DATASLOT_REQUEST_WRITE: begin
                cmd.done   = host_dataslot_request_write.done;
                cmd.result = host_dataslot_request_write.result;
            end

            CMD_STATE_DATASLOT_UPDATE: begin
                cmd.done = '1;
            end

            CMD_STATE_DATASLOT_COMPLETE: begin
                cmd.done   = host_dataslot_complete.done;
                cmd.result = bridge_pkg::host_dataslot_complete_result_ok;
            end

            CMD_STATE_RTC_UPDATE: begin
                cmd.done = '1;
            end

            CMD_STATE_SAVESTATE_START_QUERY: begin
                cmd.done     = host_savestate_start_query.done;
                cmd.result   = host_savestate_start_query.result;
                cmd.response = bridge_pkg::host_savestate_start_query_response_expand(
                    host_savestate_start_query.response
                );
            end

            CMD_STATE_SAVESTATE_LOAD_QUERY: begin
                cmd.done     = host_savestate_load_query.done;
                cmd.result   = host_savestate_load_query.result;
                cmd.response = bridge_pkg::host_savestate_load_query_response_expand(
                    host_savestate_load_query.response
                );
            end

            CMD_STATE_HOST_NOTIFY_MENU_STATE: begin
                cmd.done = '1;
            end

            CMD_STATE_HOST_NOTIFY_CARTRIDGE: begin
                cmd.done = '1;
            end

            CMD_STATE_HOST_NOTIFY_DOCKED_STATE: begin
                cmd.done = '1;
            end

            CMD_STATE_NOTIFY_DISPLAY_MODE: begin
                cmd.done     = host_notify_display_mode.done;
                cmd.response = bridge_pkg::host_notify_display_mode_response_expand(
                    host_notify_display_mode.response
                );
            end

            CMD_STATE_FORCE_EXIT: begin
                cmd.done = '1;
            end

            default: begin
                cmd.done = '1;
            end

        endcase
    end

endmodule
