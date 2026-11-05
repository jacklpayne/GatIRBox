// i2c_master_wr.v
// write-only I2C master
//   byte0 = {7-bit device addr, W=0}
//   byte1 = {reg_addr[6:0], data[8]}
//   byte2 = data[7:0]
//
// SCL frequency = clk / (4 * QDIV). With 12.288 MHz and QDIV=64 -> 48 kHz.

module i2c_master_wr #(
    parameter integer QDIV = 64            // clk cycles per quarter SCL period
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       start,               // 1-cycle pulse, ignored while busy
    input  wire [7:0] b0,
    input  wire [7:0] b1,
    input  wire [7:0] b2,
    output reg        busy,
    output reg        done,                // 1-cycle pulse when STOP finished
    output reg        nack,                // valid with done: some byte got NACK
    output reg        scl_low,
    output reg        sda_low,
    input  wire       sda_in               // raw pad input
);

    localparam [1:0] S_IDLE  = 2'd0,
                     S_START = 2'd1,
                     S_BITS  = 2'd2,
                     S_STOP  = 2'd3;

    reg [1:0]  st;
    reg [1:0]  q;          // quarter-of-bit phase
    reg [4:0]  bitn;       // 0..26 (3 x 9 bits)
    reg [26:0] sh;         // {b0,ack,b1,ack,b2,ack}, ack slots = 1 (release)
    reg [15:0] div;
    wire       tick = (div == QDIV - 1);

    // 2-FF synchronizer on SDA readback
    reg [1:0] sda_sync;
    always @(posedge clk) sda_sync <= {sda_sync[0], sda_in};
    wire sda_s = sda_sync[1];

    wire ack_slot = (bitn == 5'd8) || (bitn == 5'd17) || (bitn == 5'd26);

    always @(posedge clk) begin
        done <= 1'b0;
        if (rst) begin
            st      <= S_IDLE;
            q       <= 2'd0;
            bitn    <= 5'd0;
            sh      <= 27'd0;
            div     <= 16'd0;
            busy    <= 1'b0;
            nack    <= 1'b0;
            scl_low <= 1'b0;
            sda_low <= 1'b0;
        end else if (st == S_IDLE) begin
            div <= 16'd0;
            q   <= 2'd0;
            if (start) begin
                busy <= 1'b1;
                nack <= 1'b0;
                bitn <= 5'd0;
                sh   <= {b0, 1'b1, b1, 1'b1, b2, 1'b1};
                st   <= S_START;
            end
        end else begin
            div <= tick ? 16'd0 : div + 16'd1;
            if (tick) begin
                q <= q + 2'd1;
                case (st)
                // Bus idle (both high) -> SDA falls while SCL high -> SCL low
                S_START: case (q)
                    2'd0: begin sda_low <= 1'b0; scl_low <= 1'b0; end
                    2'd1: sda_low <= 1'b1;                 // START condition
                    2'd2: scl_low <= 1'b1;
                    2'd3: st      <= S_BITS;
                endcase
                // q0: put data on SDA (SCL low)   q1: SCL rises
                // q2: sample ACK mid-high         q3: SCL falls, shift
                S_BITS: case (q)
                    2'd0: sda_low <= ~sh[26];
                    2'd1: scl_low <= 1'b0;
                    2'd2: if (ack_slot && sda_s) nack <= 1'b1;
                    2'd3: begin
                        scl_low <= 1'b1;
                        sh      <= {sh[25:0], 1'b0};
                        if (bitn == 5'd26) st <= S_STOP;
                        else               bitn <= bitn + 5'd1;
                    end
                endcase
                // SDA low -> SCL high -> SDA rises while SCL high (STOP)
                S_STOP: case (q)
                    2'd0: sda_low <= 1'b1;
                    2'd1: scl_low <= 1'b0;
                    2'd2: sda_low <= 1'b0;                 // STOP condition
                    2'd3: begin st <= S_IDLE; busy <= 1'b0; done <= 1'b1; end
                endcase
                default: st <= S_IDLE;
                endcase
            end
        end
    end

endmodule
