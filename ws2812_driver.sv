`timescale 1ns/1ps

module ws2812_driver #(
    parameter integer PIXELS = 64
)(
    input logic clk,
    input logic [23:0] pixel_data,
    output logic [5:0] pixel_index,
    output logic data_out,
    output logic frame_done
);

    // Clock frequency is 12 MHz.
    // One clock cycle is approximately 83.3 ns.

    // Approximate timing for a 12 MHz clock.
    localparam integer T0H = 4;    // 0 bit: HIGH time
    localparam integer T0L = 8;    // 0 bit: LOW time
    localparam integer T1H = 8;    // 1 bit: HIGH time
    localparam integer T1L = 4;    // 1 bit: LOW time
    localparam integer RESET_TIME = 600; // Reset/latch LOW time

    // State numbers for the driver's four steps.
    localparam integer IDLE  = 0;
    localparam integer SEND  = 1;
    localparam integer RESET = 2;

    logic [1:0] state = IDLE;

    // Counts clock cycles for the current bit.
    logic [7:0] bit_timer = 0;

    // Counts which bit of the current pixel is being sent.
    logic [4:0] bit_index = 0;

    // Stores the current pixel's 24-bit color.
    logic [23:0] current_pixel = 0;

    // Counts which pixel is being sent.
    logic [6:0] pixel_count = 0;

    // Counts how long the output stays LOW during reset.
    logic [9:0] reset_timer = 0;

    // Select the current bit, starting with the most significant bit.
    wire current_bit = current_pixel[23 - bit_index];

    always_ff @(posedge clk) begin
        case (state)

            // Start sending the first pixel.
            IDLE: begin
                data_out <= 1'b0;
                frame_done <= 1'b0;
                pixel_index <= 0;
                pixel_count <= 0;
                bit_index <= 0;
                bit_timer <= 0;
                current_pixel <= pixel_data;
                state <= SEND;
            end

            // Send all 24 bits of the current pixel.
            SEND: begin
                // Set the output HIGH at the start of each bit.
                if (bit_timer == 0)
                    data_out <= 1'b1;

                // End the HIGH portion at the correct time.
                if (current_bit == 1'b0 && bit_timer == T0H - 1)
                    data_out <= 1'b0;

                if (current_bit == 1'b1 && bit_timer == T1H - 1)
                    data_out <= 1'b0;

                // Finish the bit after its HIGH and LOW times.
                if (current_bit == 1'b0 && bit_timer == T0H + T0L - 1) begin
                    bit_timer <= 0;

                    if (bit_index == 23) begin
                        bit_index <= 0;

                        if (pixel_count == PIXELS - 1) begin
                            state <= RESET;
                            reset_timer <= 0;
                            data_out <= 1'b0;
                        end else begin
                            pixel_count <= pixel_count + 1'b1;
                            pixel_index <= pixel_count + 1'b1;
                            current_pixel <= pixel_data;
                        end
                    end else begin
                        bit_index <= bit_index + 1'b1;
                    end
                end else if (current_bit == 1'b1 &&
                             bit_timer == T1H + T1L - 1) begin
                    bit_timer <= 0;

                    if (bit_index == 23) begin
                        bit_index <= 0;

                        if (pixel_count == PIXELS - 1) begin
                            state <= RESET;
                            reset_timer <= 0;
                            data_out <= 1'b0;
                        end else begin
                            pixel_count <= pixel_count + 1'b1;
                            pixel_index <= pixel_count + 1'b1;
                            current_pixel <= pixel_data;
                        end
                    end else begin
                        bit_index <= bit_index + 1'b1;
                    end
                end else begin
                    bit_timer <= bit_timer + 1'b1;
                end
            end

            // Keep the output LOW long enough to latch the frame.
            RESET: begin
                data_out <= 1'b0;

                if (reset_timer == RESET_TIME - 1) begin
                    reset_timer <= 0;
                    frame_done <= 1'b1;
                    state <= IDLE;
                end else begin
                    reset_timer <= reset_timer + 1'b1;
                end
            end

            default: begin
                state <= IDLE;
                data_out <= 1'b0;
                frame_done <= 1'b0;
            end

        endcase
    end

endmodule