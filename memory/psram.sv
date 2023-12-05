`timescale 1ns/1ps

module psram#(
    parameter int   CLK_FREQ = 40000000,
    parameter int   USER_CYCLES = 4,
    parameter int   ADDRESS_BITS = 23,    // include both banks
    parameter int   DATA_BITS = 16,
    parameter logic WRITE_WINS = 1'b1,    // does read or write happen first
    parameter int   RAM_CYCLE_NANOS = 72  // add 2 for delays through the IOBUFs
)(
    input  wire                                clk,
    input  wire  [ADDRESS_BITS-1:0]            rd_address,
    input  wire                                rd_en,
    output logic                               rd_ack,
    output logic [DATA_BITS-1:0]               rd_data,
    input  wire  [ADDRESS_BITS-1:0]            wr_address,
    input  wire                                wr_en,
    input  wire  [DATA_BITS-1:0]               wr_data,
    output logic                               wr_ack,

    // physical connection
    output logic [ADDRESS_BITS-2 :- DATA_BITS] cram_a,
    inout  logic [DATA_BITS-1:0]               cram_dq,
    input  logic                               cram_wait,
    output logic                               cram_clk,
    output logic                               cram_adv_n,
    output logic                               cram_cre,
    output logic                               cram_ce0_n,
    output logic                               cram_ce1_n,
    output logic                               cram_oe_n,
    output logic                               cram_we_n,
    output logic                               cram_ub_n,
    output logic                               cram_lb_n
);

    localparam real CYCLE_NANOS = 1000000000000 / CLK_FREQ;

    localparam int N1 = $ceil(RAM_CYCLE_NANOS / CYCLE_NANOS);
    localparam int N  = (N1 < 2) ? 2 : N1;

    localparam int COUNTER_BITS = $clog2(N);
    typedef logic [COUNTER_BITS-1:0] counter_t;

    //`STATIC_ASSERT(N <= USER_CYCLES)

    /*
     *          CE#     WE#    ADV#     OE#
     *  IDLE      H       H       H       H
     *
     *  READ_0    L       H       L       H
     *  READ_1    L       H       H       L
     *
     *  WRITE_0   L       L       L       H
     *  WRITE_1   L       L       H       H
     *
     *  n is max(2, ceil(70 / CYCLE_NANOS))
     *
     */

     typedef enum logic[2:0] {
        IDLE    = 3'b000,
        READ_0  = 3'b001,
        WRITE_0 = 3'b010,
        READ_1  = 3'b011,
        WRITE_1 = 3'b100
     } state_t;

    // register the address through the cycle
    logic [ADDRESS_BITS-1 : 0] address_ff;

    // register the write data through the cycle
    logic [DATA_BITS-1 : 0]    wr_data_ff;

    // deassert for chip enable - convered to CE# on the correct bank
    logic ce_n;

    // deassert for write enable - converted to WE#
    logic we_n;

    // address valid low
    logic adv_n;

    // output enable low
    logic oe_n;

    // count cycles
    counter_t counter = 0;

    // our state
    state_t state = IDLE;

    // next state in idle
    state_t next_state;

    always_comb begin
        next_state = WRITE_WINS ?
            ( wr_en ? WRITE_0 : ( rd_en ? READ_0  : IDLE ) ) :
            ( rd_en ? READ_0  : ( wr_en ? WRITE_0 : IDLE ) );
    end

    always_comb begin
        // hi-Z if output is enabled else the lower bits of the address
        // or data
        cram_dq    = oe_n ? (we_n ? address_ff[DATA_BITS-1:0] : wr_data_ff) : 'z;

        // top part of the address
        cram_a     = address_ff[ADDRESS_BITS-2 :- DATA_BITS];

        // select the correct bank using the last bit of the address
        // to select the correct CE#
        cram_ce0_n =  address_ff[ADDRESS_BITS-1] || ce_n;
        cram_ce1_n = ~address_ff[ADDRESS_BITS-1] || ce_n;
        cram_adv_n =  adv_n;
        cram_oe_n  =  oe_n;
        cram_lb_n  =  '0;
        cram_ub_n  =  '0;
        cram_clk   =  '0;
    end

    always_comb begin
        ce_n   = '1;
        we_n   = '1;
        adv_n  = '1;
        oe_n   = '1;
        rd_ack = '0;
        wr_ack = '0;

        case(state)

            IDLE: begin
                // assert ack on the same cycle
                wr_ack = (next_state == WRITE_0);
                rd_ack = (next_state == READ_0);
            end

            READ_0: begin
                ce_n   = '0;
                adv_n  = '0;
            end

            READ_1: begin
                ce_n = '0;
                oe_n = '0;
            end

            WRITE_0: begin
                ce_n   = '0;
                we_n   = '0;
                adv_n  = '0;
            end

            WRITE_1: begin
                ce_n = '0;
                we_n = '0;
            end

            default: begin
            end

        endcase
    end

    always_ff @(posedge clk) begin
        counter <= counter + 1;
        case(state)

            IDLE: begin
                case(next_state)
                    READ_0: begin
                        address_ff <= rd_address;
                    end
                    WRITE_0: begin
                        address_ff <= wr_address;
                        wr_data_ff <= wr_data;
                    end
                    default: begin
                        counter <= '0;
                    end
                endcase
            end

            READ_0: begin
                state <= READ_1;
            end

            READ_1: begin
                if(counter == N) begin
                    rd_data <= cram_dq;
                    state   <= IDLE;
                end
            end

            WRITE_0: begin
                state <= WRITE_1;
            end

            WRITE_1: begin
                if(counter == N) begin
                    state  <= IDLE;
                end
            end

            default: begin
            end

        endcase
    end

endmodule
