// Variant 1 implementation of Game of Life
// Cycle through the color wheel for each pixel, in a similar fashion to MP2

module color_fade #(
    parameter integer INC_DEC_INTERVAL = 10000,     // CLK frequency is 12MHz, so 10,000 cycles is ~833 us
    parameter integer INC_DEC_MAX = 200,            // Transition to next state after 200 increments / decrements, which is 0.2s
    parameter integer PWM_INTERVAL = 1200,          // CLK frequency is 12MHz, so 1,200 cycles is 100us
    parameter integer INC_DEC_VAL = PWM_INTERVAL / INC_DEC_MAX // 6 stages
)(
    input  logic clk,
    // outputs for every LED inside pixel instead of just one
    output logic [$clog2(PWM_INTERVAL):0] pwm_r_value,
    output logic [$clog2(PWM_INTERVAL):0] pwm_g_value,
    output logic [$clog2(PWM_INTERVAL):0] pwm_b_value
);

    // Define state variable values
    // 0: red -> yellow
    // 1: yellow -> green
    // 2: green -> cyan
    // 3: cyan -> blue
    // 4: blue -> magenta
    // 5: magenta -> red
    localparam logic [2:0] COLOR_0 = 3'd0;
    localparam logic [2:0] COLOR_1 = 3'd1;
    localparam logic [2:0] COLOR_2 = 3'd2;
    localparam logic [2:0] COLOR_3 = 3'd3;
    localparam logic [2:0] COLOR_4 = 3'd4;
    localparam logic [2:0] COLOR_5 = 3'd5;

    // declare state variables
    logic [2:0] current_state = COLOR_0;
    //declare variables for timing state transitions
    logic [$clog2(INC_DEC_INTERVAL)-1:0] count = 0;
    logic [$clog2(INC_DEC_MAX)-1:0] inc_dec_count = 0;

    // Start at full red and no green or blue.
    initial begin
        // pwm starts at red, so red will be max, and green and blue will be min
        pwm_r_value = PWM_INTERVAL;
        pwm_g_value = 0;
        pwm_b_value = 0;
    end

    // Implement counter for incrementing / decrementing PWM value
    always_ff @(posedge clk) begin
        if (count == INC_DEC_INTERVAL - 1) begin
            count <= 0;

            // Update the colors
            case (current_state)
                COLOR_0: begin
                    pwm_r_value <= PWM_INTERVAL;
                    if (pwm_g_value < PWM_INTERVAL)
                        pwm_g_value <= pwm_g_value + INC_DEC_VAL;
                    else
                        pwm_g_value <= PWM_INTERVAL;
                    pwm_b_value <= 0;
                end

                COLOR_1: begin
                    if (pwm_r_value >= INC_DEC_VAL)
                        pwm_r_value <= pwm_r_value - INC_DEC_VAL;
                    else
                        pwm_r_value <= 0;
                    pwm_g_value <= PWM_INTERVAL;
                    pwm_b_value <= 0;
                end

                COLOR_2: begin
                    pwm_r_value <= 0;
                    pwm_g_value <= PWM_INTERVAL;
                    if (pwm_b_value < PWM_INTERVAL)
                        pwm_b_value <= pwm_b_value + INC_DEC_VAL;
                    else
                        pwm_b_value <= PWM_INTERVAL;
                end

                COLOR_3: begin
                    pwm_r_value <= 0;
                    if (pwm_g_value >= INC_DEC_VAL)
                        pwm_g_value <= pwm_g_value - INC_DEC_VAL;
                    else
                        pwm_g_value <= 0;
                    pwm_b_value <= PWM_INTERVAL;
                end

                COLOR_4: begin
                    if (pwm_r_value < PWM_INTERVAL)
                        pwm_r_value <= pwm_r_value + INC_DEC_VAL;
                    else
                        pwm_r_value <= PWM_INTERVAL;
                    pwm_g_value <= 0;
                    pwm_b_value <= PWM_INTERVAL;
                end

                COLOR_5: begin
                    pwm_r_value <= PWM_INTERVAL;
                    pwm_g_value <= 0;
                    if (pwm_b_value >= INC_DEC_VAL)
                        pwm_b_value <= pwm_b_value - INC_DEC_VAL;
                    else
                        pwm_b_value <= 0;
                end

                default: begin
                    pwm_r_value <= PWM_INTERVAL;
                    pwm_g_value <= 0;
                    pwm_b_value <= 0;
                end
            endcase

            // After INC_DEC_MAX brightness updates, move to the next stage
            if (inc_dec_count == INC_DEC_MAX - 1) begin
                inc_dec_count <= 0;
                if (current_state == COLOR_5)
                    current_state <= COLOR_0;
                else
                    current_state <= current_state + 1'b1;
            end else begin
                inc_dec_count <= inc_dec_count + 1'b1;
            end
        end else begin
            count <= count + 1'b1;
        end
    end

endmodule
