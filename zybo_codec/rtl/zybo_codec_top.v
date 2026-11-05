// zybo_codec_top.v
// Zybo Z7-10 (xc7z010clg400-1), PL only: configure the on-board SSM2603
// over I2C and play a square wave out the headphone jack while SW0 is on.
//
// 48 kHz, 12.288 MHz MCLK from the 125 MHz sysclk. Codec is the I2S slave.
// Tone: sign flips every 64 samples -> 48 kHz / 128 = 375 Hz, -12 dBFS.

module zybo_codec_top (
    input  wire sysclk,        // 125 MHz
    input  wire sw0,           // 1 = tone on

    output wire ac_mclk,
    output wire ac_bclk,
    output wire ac_pblrc,
    output wire ac_reclrc,
    output wire ac_pbdat,
    output wire ac_muten,
    inout  wire ac_scl,
    inout  wire ac_sda
);

    // ---------------- MCLK: 125 / 7 * 42.75 / 62.125 = 12.288014 MHz ----------------
    wire clkfb, mclk_unbuf, mclk, locked;

    MMCME2_BASE #(
        .CLKIN1_PERIOD    (8.000),
        .DIVCLK_DIVIDE    (7),
        .CLKFBOUT_MULT_F  (42.75),     // VCO 763.39 MHz
        .CLKOUT0_DIVIDE_F (62.125)
    ) u_mmcm (
        .CLKIN1   (sysclk),
        .CLKFBIN  (clkfb),
        .CLKFBOUT (clkfb),
        .CLKOUT0  (mclk_unbuf),
        .CLKOUT0B (), .CLKOUT1 (), .CLKOUT1B (), .CLKOUT2 (), .CLKOUT2B (),
        .CLKOUT3  (), .CLKOUT3B (), .CLKOUT4 (), .CLKOUT5 (), .CLKOUT6 (),
        .CLKFBOUTB(),
        .LOCKED   (locked),
        .PWRDWN   (1'b0),
        .RST      (1'b0)
    );

    BUFG u_bufg (.I(mclk_unbuf), .O(mclk));

    ODDR #(.DDR_CLK_EDGE("SAME_EDGE")) u_oddr_mclk (
        .Q(ac_mclk), .C(mclk), .CE(1'b1), .D1(1'b1), .D2(1'b0), .R(1'b0), .S(1'b0)
    );

    // ---------------- reset + switch sync ----------------
    reg [3:0] rst_sr = 4'hF;
    always @(posedge mclk or negedge locked)
        if (!locked) rst_sr <= 4'hF;
        else         rst_sr <= {rst_sr[2:0], 1'b0};
    wire rst = rst_sr[3];

    reg [1:0] sw_s;
    always @(posedge mclk) sw_s <= {sw_s[0], sw0};

    // ---------------- codec init (I2C) ----------------
    wire init_done, scl_low, sda_low, sda_in;

    ssm2603_init u_init (
        .clk     (mclk),
        .rst     (rst),
        .done    (init_done),
        .err     (),
        .scl_low (scl_low),
        .sda_low (sda_low),
        .sda_in  (sda_in)
    );

    assign ac_muten = init_done;     // hardware mute until configured

    OBUFT u_scl (.O(ac_scl), .I(1'b0), .T(~scl_low));
    IOBUF u_sda (.IO(ac_sda), .I(1'b0), .T(~sda_low), .O(sda_in));

    // ---------------- square wave ----------------
    localparam [23:0] AMP = 24'h200000;          // 2^21 = -12 dBFS

    wire       frame;
    reg  [5:0] div;
    reg        ph;
    reg [23:0] sample;

    always @(posedge mclk) begin
        if (rst) begin
            div    <= 6'd0;
            ph     <= 1'b0;
            sample <= 24'd0;
        end else if (frame) begin
            div <= div + 6'd1;
            if (div == 6'd63) ph <= ~ph;
            sample <= !sw_s[1] ? 24'd0 : (ph ? AMP : -AMP);
        end
    end

    // ---------------- I2S out ----------------
    wire lrclk;

    i2s_tx u_i2s (
        .clk      (mclk),
        .rst      (rst),
        .tx_left  (sample),
        .tx_right (sample),
        .frame    (frame),
        .bclk     (ac_bclk),
        .lrclk    (lrclk),
        .pbdat    (ac_pbdat)
    );

    assign ac_pblrc  = lrclk;
    assign ac_reclrc = lrclk;

endmodule
