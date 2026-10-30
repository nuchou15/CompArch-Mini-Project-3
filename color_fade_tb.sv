`timescale 1ns/1ps
`include "color_fade.sv"

module color_fade_tb;
    logic clk = 1'b0;
    // RGB brightness outputs
    logic [4:0] red_value;
    logic [4:0] green_value;
    logic [4:0] blue_value;
    // Combine RGB values into one signal for GTKWave
    wire [14:0] rgb_values;
    assign rgb_values = {red_value, green_value, blue_value};
    // Tracks which color stage is being tested
    logic [2:0] stage = 0;
    // Connect the color_fade module
    color_fade #(
        .INC_DEC_INTERVAL(2),
        .INC_DEC_MAX(2),
        .PWM_INTERVAL(10),
        .INC_DEC_VAL(5)
    ) fade (
        .clk(clk),
        .pwm_r_value(red_value),
        .pwm_g_value(green_value),
        .pwm_b_value(blue_value)
    );
    // Generate clock
    always #5 clk = ~clk;
    initial begin
        // Create waveform file
        $dumpfile("color_fade.vcd");
        $dumpvars(0, color_fade_tb);
        // Check initial red color
        #1;
        if ({red_value, green_value, blue_value} !== {5'd10, 5'd0, 5'd0})
            $fatal(1, "Initial red color failed");
        // Red -> Yellow
        repeat (4) @(posedge clk);
        #1;
        stage = 1;
        if ({red_value, green_value, blue_value} !== {5'd10, 5'd10, 5'd0})
            $fatal(1, "Yellow failed");
        // Yellow -> Green
        repeat (4) @(posedge clk);
        #1;
        stage = 2;
        if ({red_value, green_value, blue_value} !== {5'd0, 5'd10, 5'd0})
            $fatal(1, "Green failed");
        // Green -> Cyan
        repeat (4) @(posedge clk);
        #1;
        stage = 3;
        if ({red_value, green_value, blue_value} !== {5'd0, 5'd10, 5'd10})
            $fatal(1, "Cyan failed");
        // Cyan -> Blue
        repeat (4) @(posedge clk);
        #1;
        stage = 4;
        if ({red_value, green_value, blue_value} !== {5'd0, 5'd0, 5'd10})
            $fatal(1, "Blue failed");
        // Blue -> Magenta
        repeat (4) @(posedge clk);
        #1;
        stage = 5;
        if ({red_value, green_value, blue_value} !== {5'd10, 5'd0, 5'd10})
            $fatal(1, "Magenta failed");
        // Magenta -> Red
        repeat (4) @(posedge clk);
        #1;
        stage = 6;
        if ({red_value, green_value, blue_value} !== {5'd10, 5'd0, 5'd0})
            $fatal(1, "Red failed");
        // Keep final color visible in GTKWave
        #100;

        $display("Pass!");
        $finish;
    end

endmodule
