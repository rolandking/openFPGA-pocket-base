`timescale 1ns/1ps

interface core_ready_to_run_if;
    logic                                             valid;
    logic                                             done;

    function automatic void tie_off();
        valid = '0;
    endfunction
endinterface

interface core_debug_event_log_if;
    logic                                             valid;
    bridge_pkg::core_debug_event_log_param_t          param;
    logic                                             done;

    function automatic void tie_off();
        valid = '0;
        param = '0;
    endfunction
endinterface

interface core_dataslot_read_if;
    logic                                             valid;
    bridge_pkg::core_dataslot_read_param_t            param;
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
module bridge_req (

    bridge_driver_if                                req,

    core_ready_to_run_if                            core_ready_to_run,
    core_debug_event_log_if                         core_debug_event_log,
    core_dataslot_read_if                           core_dataslot_read,
    core_dataslot_write_if                          core_dataslot_write,
    core_dataslot_flush_if                          core_dataslot_flush,
    core_get_dataslot_filename_if                   core_get_dataslot_filename,
    core_open_dataslot_file_if                      core_open_dataslot_file
);


    // start in IDLE state, when one of the requests, in priority,
    // is asserted move to that state. Wait for request read and the
    // response to be written before checking for ok.
    // state
    typedef enum logic[2:0] {
        REQ_STATE_IDLE                  = 3'd0,
        REQ_STATE_OPEN_DATASLOT_FILE    = 3'd1,
        REQ_STATE_GET_DATASLOT_FILENAME = 3'd2,
        REQ_STATE_DATASLOT_FLUSH        = 3'd3,
        REQ_STATE_DATASLOT_WRITE        = 3'd4,
        REQ_STATE_DATASLOT_READ         = 3'd5,
        REQ_STATE_DEBUG_EVENT_LOG       = 3'd6,
        REQ_STATE_READY_TO_RUN          = 3'd7
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

    req_state_e req_state = REQ_STATE_IDLE;

    always_comb begin
        req.word = '0;
        req.param = 'x;

        case(req_state)
            REQ_STATE_IDLE: begin
            end
            REQ_STATE_READY_TO_RUN: begin
                req.word           = bridge_pkg::core_ready_to_run;
                core_ready_to_run.done = req.done;
            end
            REQ_STATE_DEBUG_EVENT_LOG: begin
                req.word  = bridge_pkg::core_debug_event_log;
                req.param = bridge_pkg::core_debug_event_log_param_expand(
                    core_debug_event_log.param
                );
                core_debug_event_log.done = req.done;
            end
            REQ_STATE_DATASLOT_READ: begin
                req.word  = bridge_pkg::core_dataslot_read;
                req.param = bridge_pkg::core_dataslot_read_param_expand(
                    core_dataslot_read.param
                );
                core_dataslot_read.done = req.done;
            end
            REQ_STATE_DATASLOT_WRITE: begin
                req.word  = bridge_pkg::core_dataslot_write;
                req.param = bridge_pkg::core_dataslot_write_param_expand(
                    core_dataslot_write.param
                );
                core_dataslot_write.done = req.done;
            end
            REQ_STATE_DATASLOT_FLUSH: begin
                req.word  = bridge_pkg::core_dataslot_flush;
                req.param = bridge_pkg::core_dataslot_flush_param_expand(
                    core_dataslot_flush.param
                );
                core_dataslot_flush.done = req.done;
            end
            REQ_STATE_GET_DATASLOT_FILENAME: begin
                req.word  = bridge_pkg::core_get_dataslot_filename;
                req.param = bridge_pkg::core_get_dataslot_filename_param_expand(
                    core_get_dataslot_filename.param
                );
                core_get_dataslot_filename.done = req.done;
            end
            REQ_STATE_OPEN_DATASLOT_FILE: begin
                req.word  = bridge_pkg::core_open_dataslot_file;
                req.param = bridge_pkg::core_open_dataslot_file_param_expand(
                    core_open_dataslot_file.param
                );
                core_open_dataslot_file.done = req.done;
            end
            default: begin
            end
        endcase
    end


    // if idle and there's a priority state, move to it
    // capturing the parameters
    always_ff @(posedge req.clk) begin
        if(req_state == REQ_STATE_IDLE) begin
            req_state <= priority_state;
        end else begin
            if(req.done) begin
                req_state <= REQ_STATE_IDLE;
            end
        end
    end

    always_comb begin
        req.valid    = (req_state != REQ_STATE_IDLE);
        req.response = '0;
    end

    always_comb begin
        req.word                    = '0;
        req.param                   = '0;

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
                req.word           = bridge_pkg::core_ready_to_run;
                core_ready_to_run.ack  = req.ack;
                core_ready_to_run.done = req.done;
            end
            REQ_STATE_DEBUG_EVENT_LOG: begin
                req.word  = bridge_pkg::core_debug_event_log;
                req.param = bridge_pkg::core_debug_event_log_param_expand(
                    core_debug_event_log.param
                );
                core_debug_event_log.ack  = req.ack;
                core_debug_event_log.done = req.done;
            end
            REQ_STATE_DATASLOT_READ: begin
                req.word  = bridge_pkg::core_dataslot_read;
                req.param = bridge_pkg::core_dataslot_read_param_expand(
                    core_dataslot_read.param
                );
                core_dataslot_read.ack  = req.ack;
                core_dataslot_read.done = req.done;
            end
            REQ_STATE_DATASLOT_WRITE: begin
                req.word  = bridge_pkg::core_dataslot_write;
                req.param = bridge_pkg::core_dataslot_write_param_expand(
                    core_dataslot_write.param
                );
                core_dataslot_write.ack  = req.ack;
                core_dataslot_write.done = req.done;
            end
            REQ_STATE_DATASLOT_FLUSH: begin
                req.word  = bridge_pkg::core_dataslot_flush;
                req.param = bridge_pkg::core_dataslot_flush_param_expand(
                    core_dataslot_flush.param
                );
                core_dataslot_flush.ack  = req.ack;
                core_dataslot_flush.done = req.done;
            end
            REQ_STATE_GET_DATASLOT_FILENAME: begin
                req.word  = bridge_pkg::core_get_dataslot_filename;
                req.param = bridge_pkg::core_get_dataslot_filename_param_expand(
                    core_get_dataslot_filename.param
                );
                core_get_dataslot_filename.ack  = req.ack;
                core_get_dataslot_filename.done = req.done;
            end
            REQ_STATE_OPEN_DATASLOT_FILE: begin
                req.word  = bridge_pkg::core_open_dataslot_file;
                req.param = bridge_pkg::core_open_dataslot_file_param_expand(
                    core_open_dataslot_file.param
                );
                core_open_dataslot_file.ack  = req.ack;
                core_open_dataslot_file.done = req.done;
            end

            default: begin
            end
        endcase
    end

endmodule
