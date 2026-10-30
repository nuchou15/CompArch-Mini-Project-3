`include "next_gen.sv"
`include "color_fade.sv"
`include "ws2812_driver.sv"

module top #(
    parameter integer LIFE_GENERATION_DIV = 112, // update after 122 frames
    parameter SEED_FILE = "seed.memh", // memory file with initial state
    // parameters taken from MP2
    parameter integer INC_DEC_INTERVAL = 10000,
    parameter integer INC_DEC_MAX = 200,
    parameter integer PWM_INTERVAL = 1200,
    parameter integer INC_DEC_VAL = PWM_INTERVAL / INC_DEC_MAX
)(
    input  logic clk,
    output logic _48b
);

    // 1 = alive. 0 = dead. 64 cells means 64 bits
    logic [63:0] alive;
    logic generation_tick = 1'b0; // one clock tick means to calculate and move to next gen
    logic [$clog2(LIFE_GENERATION_DIV)-1:0] life_frame_count = 0;

    // for the LED matrix
    logic [5:0] pixel_index; // which physical pixel is being transmitted
    logic frame_done; // high for one clock cycle when a complete LED frame and reset interval stop transmitting
    logic [23:0] pixel_data; // 24 bits b/c 3 8-bit color channels

    // current rgb brightness values from color_fade module
    logic [$clog2(PWM_INTERVAL):0] pwm_r_value;
    logic [$clog2(PWM_INTERVAL):0] pwm_g_value;
    logic [$clog2(PWM_INTERVAL):0] pwm_b_value;

    // Save the brightness values for each LED frame
    logic [$clog2(PWM_INTERVAL):0] frame_r_value = PWM_INTERVAL;
    logic [$clog2(PWM_INTERVAL):0] frame_g_value = 0;
    logic [$clog2(PWM_INTERVAL):0] frame_b_value = 0;

    // Convert brightness to 8-bit color values
    // Not exactly sure why, but I had to implement this to fix my clock timing issue
    logic [7:0] frame_r_byte = 8'd255; // initially red
    logic [7:0] frame_g_byte = 8'd0;
    logic [7:0] frame_b_byte = 8'd0;

    // convert brightness from 0-pwm_interval to 0-255 
    // we do multiplication followed by a right shift (instead of straight up division)
    localparam integer COLOR_SCALE = (255 * 65536) / PWM_INTERVAL;

    // mapping the physical LED order to the grid
    logic [2:0] physical_row;
    logic [2:0] physical_col;
    logic [2:0] logical_col;
    logic [5:0] logical_pixel_index; // used to select a cell in alive vector

    // we will now load the initial state and update generations
    next_gen #(
        .SEED_FILE(SEED_FILE)
    ) life (
        .clk(clk),
        .generation_tick(generation_tick),
        .alive(alive)
    );

    // Variant 1 implementation
    color_fade #(
        .INC_DEC_INTERVAL(INC_DEC_INTERVAL),
        .INC_DEC_MAX(INC_DEC_MAX),
        .PWM_INTERVAL(PWM_INTERVAL),
        .INC_DEC_VAL(INC_DEC_VAL)
    ) fade_rgb (
        .clk(clk),
        .pwm_r_value(pwm_r_value),
        .pwm_g_value(pwm_g_value),
        .pwm_b_value(pwm_b_value)
    );

    always_ff @(posedge clk) begin
        generation_tick <= 1'b0;

        // if a frame has been completed
        if (frame_done) begin
            // capture brightness values
            frame_r_value <= pwm_r_value;
            frame_g_value <= pwm_g_value;
            frame_b_value <= pwm_b_value;

            // Convert brightness from 0-PWM_INTERVAL to 0-255
            frame_r_byte <= (pwm_r_value * COLOR_SCALE) >> 16;
            frame_g_byte <= (pwm_g_value * COLOR_SCALE) >> 16;
            frame_b_byte <= (pwm_b_value * COLOR_SCALE) >> 16;

            // Determine when to update
            if (life_frame_count == LIFE_GENERATION_DIV - 1) begin
                life_frame_count <= 0; // restart frame counter for next gen
                generation_tick <= 1'b1;
            end else begin
                life_frame_count <= life_frame_count + 1'b1;
            end
        end
    end

    // physical grid must match the logical one
    always_comb begin
        logical_pixel_index = pixel_index;
    end

    // determine color. living cells show the saved color (rgb), dead cells are black.
    always_comb begin
        if (alive[logical_pixel_index]) begin
            pixel_data = {frame_g_byte, frame_r_byte, frame_b_byte};
        end else begin
            // NO color for the dead cells
            pixel_data = 24'h000000;
        end
    end

    // Send the colors to the matrix.
    ws2812_driver #(
        .PIXELS(64) // 64 leds
    ) matrix_driver (
        .clk(clk),
        .pixel_data(pixel_data), // current pixel color data
        .pixel_index(pixel_index), // current pixel index returned to top 
        .data_out(_48b),
        .frame_done(frame_done) // completed LED frame
    );

endmodule