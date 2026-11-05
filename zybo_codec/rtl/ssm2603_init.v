// ssm2603_init.v
// Power-up / configuration sequencer for the Analog Devices SSM2603
//
// Codec mode set here:
//   - Slave mode: FPGA drives MCLK, BCLK (64 fs), PBLRC and RECLRC
//   - I2S format, 24-bit words
//   - Line in -> ADC, DAC -> headphone out; mic and analog bypass off
//   - Normal (non-USB) mode, 256 fs: 12.288 MHz MCLK -> 48 kHz
//
// Register write frame (16 bits): {reg_addr[6:0], data[8:0]}
//

module ssm2603_init #(
    parameter integer CLK_HZ  = 12_288_000,
    parameter integer QDIV    = 64,         // I2C quarter-period in clk cycles
    parameter integer MS_DIV  = 0           // override cycles/ms (sim); 0 = CLK_HZ/1000
)(
    input  wire clk,
    input  wire rst,
    output reg  done,          // level: codec configured, safe to unmute
    output reg  err,           // level: at least one write was NACKed
    output wire scl_low,
    output wire sda_low,
    input  wire sda_in
);

    // ---------------- Register values ----------------
    // R0  Left ADC vol:  LRINBOTH=1, LINMUTE=0, LINVOL=0x17 (0 dB)
    //                    LINVOL steps 1.5 dB, 0x00 = -34.5 dB, 0x3F = +33 dB
    localparam [8:0] R0_LIN_VOL  = 9'h117;
    // R2  Left HP vol:   LRHPBOTH=1, LHPVOL=0x79 (0 dB); 0x7F = +6 dB
    localparam [8:0] R2_HP_VOL   = 9'h179;
    // R4  Analog path:   DACSEL=1, BYPASS=0, INSEL=0 (line), MUTEMIC=1
    localparam [8:0] R4_APATH    = 9'h012;
    // R5  Digital path:  DACMU=0 (unmuted), no de-emphasis, ADC HPF on
    localparam [8:0] R5_DPATH    = 9'h000;
    // R6  Power mgmt (1 = powered DOWN):
    //     D7 PWROFF D6 CLKOUT D5 OSC D4 OUT D3 DAC D2 ADC D1 MIC D0 LINEIN
    //     0x067: chip+OUT+DAC on, rest off      (first-power-up workaround)
    //     0x072: chip, DAC, ADC, LINEIN on; OUT still off
    //     0x062: same + OUT on
    localparam [8:0] R6_WORKAROUND = 9'h067;
    localparam [8:0] R6_NO_OUT     = 9'h072;
    localparam [8:0] R6_ALL_ON     = 9'h062;
    // R7  Digital I/F:   BCLKINV=0, MS=0 (slave), LRSWAP=0, LRP=0,
    //                    WL=10 (24-bit), FORMAT=10 (I2S)
    localparam [8:0] R7_DAI      = 9'h00A;
    // R8  Sampling rate: USB=0, BOSR=0 (256 fs), SR=0000 -> 48 kHz @ 12.288 MHz
    localparam [8:0] R8_SR       = 9'h000;
    // R9  Active
    localparam [8:0] R9_ACTIVE   = 9'h001;
    // R15 Software reset: write anything
    localparam [8:0] R15_RESET   = 9'h000;

    localparam [7:0] DEV_ADDR_W = {7'h1A, 1'b0};   // CSB tied low on Zybo Z7

    // ---------------- Sequence ROM ----------------
    // Each entry: {reg[6:0], data[8:0], delay_ms_after[7:0]}
    localparam integer N_STEPS = 13;
    reg [3:0]  step;
    reg [23:0] rom;
    always @(*) begin
        case (step)
            4'd0:  rom = {7'h09, R9_ACTIVE,     8'd1  };  // workaround: core on
            4'd1:  rom = {7'h06, R6_WORKAROUND, 8'd10 };  //   chip+DAC+OUT together
            4'd2:  rom = {7'h0F, R15_RESET,     8'd5  };  // soft reset to defaults
            4'd3:  rom = {7'h06, R6_NO_OUT,     8'd1  };  // power up, output off
            4'd4:  rom = {7'h00, R0_LIN_VOL,    8'd0  };
            4'd5:  rom = {7'h02, R2_HP_VOL,     8'd0  };
            4'd6:  rom = {7'h04, R4_APATH,      8'd0  };
            4'd7:  rom = {7'h05, R5_DPATH,      8'd0  };
            4'd8:  rom = {7'h07, R7_DAI,        8'd0  };
            4'd9:  rom = {7'h08, R8_SR,         8'd200};  // VMID charge time
            4'd10: rom = {7'h09, R9_ACTIVE,     8'd5  };  // digital core on
            4'd11: rom = {7'h06, R6_ALL_ON,     8'd20 };  // output on last
            default: rom = {7'h06, R6_ALL_ON,   8'd0  };  // (step 12 = finished)
        endcase
    end

    // ---------------- ms timebase ----------------
    localparam integer CYC_PER_MS = (MS_DIV != 0) ? MS_DIV : (CLK_HZ / 1000);
    reg [17:0] ms_cnt;
    wire       ms_tick = (ms_cnt == CYC_PER_MS - 1);
    always @(posedge clk) begin
        if (rst || ms_tick) ms_cnt <= 18'd0;
        else                ms_cnt <= ms_cnt + 18'd1;
    end

    // ---------------- Sequencer ----------------
    localparam [1:0] Q_PWRWAIT = 2'd0,
                     Q_SEND    = 2'd1,
                     Q_BUSY    = 2'd2,
                     Q_DELAY   = 2'd3;

    reg [1:0] qs;
    reg [7:0] dly;
    reg       i2c_start;
    wire      i2c_busy, i2c_done, i2c_nack;

    always @(posedge clk) begin
        i2c_start <= 1'b0;
        if (rst) begin
            qs   <= Q_PWRWAIT;
            step <= 4'd0;
            dly  <= 8'd20;       // let codec rails / MCLK settle after config
            done <= 1'b0;
            err  <= 1'b0;
        end else begin
            case (qs)
            Q_PWRWAIT: if (ms_tick) begin
                if (dly == 8'd0) qs <= Q_SEND;
                else             dly <= dly - 8'd1;
            end
            Q_SEND: begin
                if (step == N_STEPS - 1) begin
                    done <= 1'b1;            // stay here forever
                end else if (!i2c_busy) begin
                    i2c_start <= 1'b1;
                    qs        <= Q_BUSY;
                end
            end
            Q_BUSY: if (i2c_done) begin
                if (i2c_nack) err <= 1'b1;
                dly <= rom[7:0];
                qs  <= Q_DELAY;
            end
            Q_DELAY: begin
                if (dly == 8'd0) begin
                    step <= step + 4'd1;
                    qs   <= Q_SEND;
                end else if (ms_tick) begin
                    dly <= dly - 8'd1;
                end
            end
            endcase
        end
    end

    i2c_master_wr #(.QDIV(QDIV)) u_i2c (
        .clk     (clk),
        .rst     (rst),
        .start   (i2c_start),
        .b0      (DEV_ADDR_W),
        .b1      (rom[23:16]),      // {reg[6:0], data[8]}
        .b2      (rom[15:8]),       // data[7:0]
        .busy    (i2c_busy),
        .done    (i2c_done),
        .nack    (i2c_nack),
        .scl_low (scl_low),
        .sda_low (sda_low),
        .sda_in  (sda_in)
    );

endmodule
