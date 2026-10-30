`timescale 1ns/1ps
`include "color_fade.sv"

// test Color_fade / variant 1
module color_fade_tb;
    logic clk = 1'b0;
    // red, green, and blue brightness outputs
    logic [4:0] red_value;
    logic [4:0] green_value;
    logic [4:0] blue_value;

    color_fade #(
        .INC_DEC_INTERVAL(2),
        .INC_DEC_MAX(2),
        .PWM_INTERVAL(10),
        .INC_DEC_VAL(5)
    ) u0 (
        .clk(clk),
        .pwm_r_value(red_value),
        .pwm_g_value(green_value),
        .pwm_b_value(blue_value)
    );

    always #5 clk = ~clk; // invert clock every 5 ns, this produces 10ns clock period (100MHz)

    initial begin
        $dumpfile("color_fade.vcd");
        $dumpvars(0, color_fade_tb);

        // Check initial color is red
        #1;
        if ({red_value, green_value, blue_value} !== {5'd10, 5'd0, 5'd0})
            $fatal(1, "Initial color is not red");

        // Wait four clock cycles, then check yellow
        repeat (4) @(posedge clk);
        #1;
        if ({red_value, green_value, blue_value} !== {5'd10, 5'd10, 5'd0})
            $fatal(1, "No yellow");

        // Check green
        repeat (4) @(posedge clk);
        #1;
        if ({red_value, green_value, blue_value} !== {5'd0, 5'd10, 5'd0})
            $fatal(1, "No green");

        // Check cyan
        repeat (4) @(posedge clk);
        #1;
        if ({red_value, green_value, blue_value} !== {5'd0, 5'd10, 5'd10})
            $fatal(1, "No cyan");

        // Ceck blue
        repeat (4) @(posedge clk);
        #1;
        if ({red_value, green_value, blue_value} !== {5'd0, 5'd0, 5'd10})
            $fatal(1, "No Blue");

        // check magenta
        repeat (4) @(posedge clk);
        #1;
        if ({red_value, green_value, blue_value} !== {5'd10, 5'd0, 5'd10})
            $fatal(1, "No magenta");

        // check that the color returns to red
        repeat (4) @(posedge clk);
        #1;
        if ({red_value, green_value, blue_value} !== {5'd10, 5'd0, 5'd0})
            $fatal(1, "Red didn't come around again");

        $display("All colors cycled through!");
        $finish;
    end

endmodule