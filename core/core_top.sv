`timescale 1ns/1ps

module core_top (

    //
    // physical connections
    //

    ///////////////////////////////////////////////////
    // clock inputs 74.25mhz. not phase aligned, so treat these domains as asynchronous

    input   wire            clk_74a, // mainclk1
    input   wire            clk_74b, // mainclk1

    ///////////////////////////////////////////////////
    // cartridge interface
    // switches between 3.3v and 5v mechanically
    // output enable for multibit translators controlled by pic32

    // GBA AD[15:8]
    inout   wire    [7:0]   cart_tran_bank2,
    output  wire            cart_tran_bank2_dir,

    // GBA AD[7:0]
    inout   wire    [7:0]   cart_tran_bank3,
    output  wire            cart_tran_bank3_dir,

    // GBA A[23:16]
    inout   wire    [7:0]   cart_tran_bank1,
    output  wire            cart_tran_bank1_dir,

    // GBA [7] PHI#
    // GBA [6] WR#
    // GBA [5] RD#
    // GBA [4] CS1#/CS#
    //     [3:0] unwired
    inout   wire    [7:4]   cart_tran_bank0,
    output  wire            cart_tran_bank0_dir,

    // GBA CS2#/RES#
    inout   wire            cart_tran_pin30,
    output  wire            cart_tran_pin30_dir,
    // when GBC cart is inserted, this signal when low or weak will pull GBC /RES low with a special circuit
    // the goal is that when unconfigured, the FPGA weak pullups won't interfere.
    // thus, if GBC cart is inserted, FPGA must drive this high in order to let the level translators
    // and general IO drive this pin.
    output  wire            cart_pin30_pwroff_reset,

    // GBA IRQ/DRQ
    inout   wire            cart_tran_pin31,
    output  wire            cart_tran_pin31_dir,

    // infrared
    input   wire            port_ir_rx,
    output  wire            port_ir_tx,
    output  wire            port_ir_rx_disable,

    // GBA link port
    inout   wire            port_tran_si,
    output  wire            port_tran_si_dir,
    inout   wire            port_tran_so,
    output  wire            port_tran_so_dir,
    inout   wire            port_tran_sck,
    output  wire            port_tran_sck_dir,
    inout   wire            port_tran_sd,
    output  wire            port_tran_sd_dir,

    ///////////////////////////////////////////////////
    // cellular psram 0 and 1, two chips (64mbit x2 dual die per chip)

    output  wire    [21:16] cram0_a,
    inout   wire    [15:0]  cram0_dq,
    input   wire            cram0_wait,
    output  wire            cram0_clk,
    output  wire            cram0_adv_n,
    output  wire            cram0_cre,
    output  wire            cram0_ce0_n,
    output  wire            cram0_ce1_n,
    output  wire            cram0_oe_n,
    output  wire            cram0_we_n,
    output  wire            cram0_ub_n,
    output  wire            cram0_lb_n,

    output  wire    [21:16] cram1_a,
    inout   wire    [15:0]  cram1_dq,
    input   wire            cram1_wait,
    output  wire            cram1_clk,
    output  wire            cram1_adv_n,
    output  wire            cram1_cre,
    output  wire            cram1_ce0_n,
    output  wire            cram1_ce1_n,
    output  wire            cram1_oe_n,
    output  wire            cram1_we_n,
    output  wire            cram1_ub_n,
    output  wire            cram1_lb_n,

    ///////////////////////////////////////////////////
    // sdram, 512mbit 16bit

    output  wire    [12:0]  dram_a,
    output  wire    [1:0]   dram_ba,
    inout   wire    [15:0]  dram_dq,
    output  wire    [1:0]   dram_dqm,
    output  wire            dram_clk,
    output  wire            dram_cke,
    output  wire            dram_ras_n,
    output  wire            dram_cas_n,
    output  wire            dram_we_n,

    ///////////////////////////////////////////////////
    // sram, 1mbit 16bit

    output  wire    [16:0]  sram_a,
    inout   wire    [15:0]  sram_dq,
    output  wire            sram_oe_n,
    output  wire            sram_we_n,
    output  wire            sram_ub_n,
    output  wire            sram_lb_n,

    ///////////////////////////////////////////////////
    // vblank driven by dock for sync in a certain mode

    input   wire            vblank,

    ///////////////////////////////////////////////////
    // i/o to 6515D breakout usb uart

    output  wire            dbg_tx,
    input   wire            dbg_rx,

    ///////////////////////////////////////////////////
    // i/o pads near jtag connector user can solder to

    output  wire            user1,
    input   wire            user2,

    ///////////////////////////////////////////////////
    // RFU internal i2c bus

    inout   wire            aux_sda,
    output  wire            aux_scl,

    ///////////////////////////////////////////////////
    // RFU, do not use
    output  wire            vpll_feed,


    //
    // logical connections
    //

    ///////////////////////////////////////////////////
    // video, audio output to scaler
    output  wire    [23:0]  video_rgb,
    output  wire            video_rgb_clock,
    output  wire            video_rgb_clock_90,
    output  wire            video_de,
    output  wire            video_skip,
    output  wire            video_vs,
    output  wire            video_hs,

    output  wire            audio_mclk,
    input   wire            audio_adc,
    output  wire            audio_dac,
    output  wire            audio_lrck,

    ///////////////////////////////////////////////////
    // bridge bus connection
    // synchronous to clk_74a
    output  wire            bridge_endian_little,
    input   wire    [31:0]  bridge_addr,
    input   wire            bridge_rd,
    output  reg     [31:0]  bridge_rd_data,
    input   wire            bridge_wr,
    input   wire    [31:0]  bridge_wr_data,

    ///////////////////////////////////////////////////
    // controller data
    //
    // key bitmap:
    //   [0]    dpad_up
    //   [1]    dpad_down
    //   [2]    dpad_left
    //   [3]    dpad_right
    //   [4]    face_a
    //   [5]    face_b
    //   [6]    face_x
    //   [7]    face_y
    //   [8]    trig_l1
    //   [9]    trig_r1
    //   [10]   trig_l2
    //   [11]   trig_r2
    //   [12]   trig_l3
    //   [13]   trig_r3
    //   [14]   face_select
    //   [15]   face_start
    //   [31:28] type
    // joy values - unsigned
    //   [ 7: 0] lstick_x
    //   [15: 8] lstick_y
    //   [23:16] rstick_x
    //   [31:24] rstick_y
    // trigger values - unsigned
    //   [ 7: 0] ltrig
    //   [15: 8] rtrig
    //
    input   wire    [31:0]  cont1_key,
    input   wire    [31:0]  cont2_key,
    input   wire    [31:0]  cont3_key,
    input   wire    [31:0]  cont4_key,
    input   wire    [31:0]  cont1_joy,
    input   wire    [31:0]  cont2_joy,
    input   wire    [31:0]  cont3_joy,
    input   wire    [31:0]  cont4_joy,
    input   wire    [15:0]  cont1_trig,
    input   wire    [15:0]  cont2_trig,
    input   wire    [15:0]  cont3_trig,
    input   wire    [15:0]  cont4_trig
);
    /// wire up the bridge
    bus_if#(
        .addr_width (32),
        .data_width (32)
    ) bridge(.clk(clk_74a));

    bridge_connect bc(
        .addr    (bridge_addr   ),
        .wr_data (bridge_wr_data),
        .wr      (bridge_wr     ),
        .rd_data (bridge_rd_data),
        .rd      (bridge_rd     ),
        .bridge  (bridge        )
    );

    port_if #( .lo_index(4)) port_cart_tran_bank0 ();
    port_connect #(
        .hi_index (7),
        .lo_index (4)
    ) pctb0 (
        .port_data   (cart_tran_bank0      ),
        .port_dir    (cart_tran_bank0_dir  ),
        .port        (port_cart_tran_bank0 )
    );

    port_if port_cart_tran_bank1 ();
    port_connect #(
        .hi_index (7),
        .lo_index (0)
    ) pctb1 (
        .port_data   ( cart_tran_bank1     ),
        .port_dir    (cart_tran_bank1_dir  ),
        .port        (port_cart_tran_bank1 )
    );

    port_if port_cart_tran_bank2();
    port_connect #(
        .hi_index (7),
        .lo_index (0)
    ) pctb2 (
        .port_data   ( cart_tran_bank2     ),
        .port_dir    (cart_tran_bank2_dir  ),
        .port        (port_cart_tran_bank2 )
    );

    port_if port_cart_tran_bank3();
    port_connect #(
        .hi_index (7),
        .lo_index (0)
    ) pctb3 (
        .port_data   ( cart_tran_bank3     ),
        .port_dir    (cart_tran_bank3_dir  ),
        .port        (port_cart_tran_bank3 )
    );

    port_if #( .hi_index(0)) port_cart_tran_pin30();
    port_connect #(
        .hi_index (0),
        .lo_index (0)
    ) pctp30 (
        .port_data   (cart_tran_pin30     ),
        .port_dir    (cart_tran_pin30_dir ),
        .port        (port_cart_tran_pin30)
    );

    port_if #(.hi_index(0)) port_cart_tran_pin31();
    port_connect #(
        .hi_index (0),
        .lo_index (0)
    ) pctp31 (
        .port_data   (cart_tran_pin31     ),
        .port_dir    (cart_tran_pin31_dir ),
        .port        (port_cart_tran_pin31)
    );

    ir_if ir();
    ir_connect irc (
        .tx         (port_ir_tx),
        .rx_disable (port_ir_rx_disable),
        .rx         (port_ir_rx),

        .ir         (ir)
    );

    gba_if gba();
    gba_connect gbac(
        .port_si      (port_tran_si     ),
        .port_si_dir  (port_tran_si_dir ),
        .port_so      (port_tran_so     ),
        .port_so_dir  (port_tran_so_dir ),
        .port_sck     (port_tran_sck    ),
        .port_sck_dir (port_tran_sck_dir),
        .port_sd      (port_tran_sd     ),
        .port_sd_dir  (port_tran_sd_dir ),

        .gba          (gba)
    );

    cram_if cram0();
    cram_connect cc0(
        .a     (cram0_a),
        .dq    (cram0_dq),
        .clk   (cram0_clk),
        ._wait (cram0_wait),
        .adv_n (cram0_adv_n),
        .cre   (cram0_cre),
        .ce0_n (cram0_ce0_n),
        .ce1_n (cram0_ce1_n),
        .oe_n  (cram0_oe_n),
        .we_n  (cram0_we_n),
        .ub_n  (cram0_ub_n),
        .lb_n  (cram0_lb_n),

        .cram  (cram0)
    );

    cram_if cram1();
    cram_connect cc1(
        .a     (cram1_a),
        .dq    (cram1_dq),
        .clk   (cram1_clk),
        ._wait (cram1_wait),
        .adv_n (cram1_adv_n),
        .cre   (cram1_cre),
        .ce0_n (cram1_ce0_n),
        .ce1_n (cram1_ce1_n),
        .oe_n  (cram1_oe_n),
        .we_n  (cram1_we_n),
        .ub_n  (cram1_ub_n),
        .lb_n  (cram1_lb_n),

        .cram  (cram1)
    );

    dram_if dram();
    dram_connect dc(
        .a       (dram_a     ),
        .ba      (dram_ba    ),
        .dq      (dram_dq    ),
        .dqm     (dram_dqm   ),
        .clk     (dram_clk   ),
        .cke     (dram_cke   ),
        .ras_n   (dram_ras_n ),
        .cas_n   (dram_cas_n ),
        .we_n    (dram_we_n  ),
        .dram    (dram       )
    );

    sram_if sram();
    sram_connect src(
        .a      (sram_a),
        .dq     (sram_dq),
        .oe_n   (sram_oe_n),
        .we_n   (sram_we_n),
        .ub_n   (sram_ub_n),
        .lb_n   (sram_lb_n),

        .sram   (sram)
    );

    video_if video(
        .rgb_clk       (video_rgb_clock),
        .rgb_clk_90    (video_rgb_clock_90)
    );
    video_connect vc (
        .rgb           (video_rgb         ),
        .de            (video_de          ),
        .skip          (video_skip        ),
        .vs            (video_vs          ),
        .hs            (video_hs          ),
        .video         (video             )
    );

    audio_if audio();
    audio_connect ac(
        .mclk     (audio_mclk),
        .adc      (audio_adc ),
        .dac      (audio_dac ),
        .lrck     (audio_lrck),
        .audio    (audio     )
    );

    controller_if controller[1:4]();

    controller_connect con1(
        .key         (cont1_key),
        .joy         (cont1_joy),
        .trig        (cont1_trig),
        .controller  (controller[1])
    );

    controller_connect con2(
        .key         (cont2_key),
        .joy         (cont2_joy),
        .trig        (cont2_trig),
        .controller  (controller[2])
    );

    controller_connect con3(
        .key         (cont3_key),
        .joy         (cont3_joy),
        .trig        (cont3_trig),
        .controller  (controller[3])
    );

    controller_connect con4(
        .key         (cont4_key),
        .joy         (cont4_joy),
        .trig        (cont4_trig),
        .controller  (controller[4])
    );

    /*
     * these pins are not used so tie them off here and don't pass them
     * to the user core
     */
    always_comb begin
        dbg_tx    = 'z;
        user1     = 'z;
        vpll_feed = 'z;
        aux_sda   = 'z;
        aux_scl   = 'x;
    end

    user_top user (

        // physical connections
        //
        .clk_74a,
        .clk_74b,

        .port_cart_tran_bank0,
        .port_cart_tran_bank1,
        .port_cart_tran_bank2,
        .port_cart_tran_bank3,

        .port_cart_tran_pin30,
        .cart_pin30_pwroff_reset,
        .port_cart_tran_pin31,

        .ir,

        .gba,

        .cram0,
        .cram1,

        .dram,

        .sram,

        .vblank,

        // logical connections with user core
        .video,
        .audio,

        .bridge_endian_little,
        .bridge,

        .controller
    );

    endmodule
