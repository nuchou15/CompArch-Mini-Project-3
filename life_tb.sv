`timescale 10ns/10ns
`include "next_gen.sv"

// Testbench the actual game
module life_tb;

    logic clk = 1'b0;

    // Controls when the Game of Life advances to the next generation
    // 0 = hold current generation, 1 = advance to next
    logic generation_tick = 1'b0;

    // 1 = alive, 0 = dead.
    logic [63:0] blinker_alive;
    logic [63:0] wrap_alive;

    next_gen #(
        .SEED_FILE("test_life.memh") // load initial pattern
    ) u1 (
        .clk(clk),
        .generation_tick(generation_tick),
        .alive(blinker_alive)
    );

    next_gen #(
        .SEED_FILE("wrap_blinker.memh") // load other pattern
    ) u2 (
        .clk(clk),
        .generation_tick(generation_tick),
        .alive(wrap_alive)
    );

    // invert clock
    always begin
        #4;
        clk = ~clk;
    end

    initial begin

        $dumpfile("life.vcd");
        $dumpvars(0, life_tb);

        // check initial grids
        repeat (2) @(posedge clk); // wait for two posedge clk so we can load 

        // slight delay
        #1;

        // Print both starting grids in hexadecimal
        $display("Initial blinker: %016h", blinker_alive);
        $display("Initial wrap blinker: %016h", wrap_alive);

        // Verify that the normal blinker loaded correctly
        // !== also detects unknown or high-impedance bits
        if (blinker_alive !== 64'h0000000808080000) begin
            $display("FAIL: Initial blinker seed is incorrect.");
            $finish;
        end

        // confirm that the wraparound seed loaded correctly
        if (wrap_alive !== 64'h0100000000000101) begin
            $display("Fail lol");
            $finish;
        end

        // gen 1
        @(negedge clk);
        generation_tick = 1'b1;
        @(negedge clk);

        // Stop requesting updates
        generation_tick = 1'b0;
        #1;

        // The vertical blinker should now be horizontal
        if (blinker_alive !== 64'h000000001c000000) begin
            $display("Failed: gen 1 is incorrect.");
            $finish;
        end

        // wrapound blinker should be horizontal too
        if (wrap_alive !== 64'h0000000000000083) begin
            $display("FAIL: Wraparound blinker generation 1 is incorrect.");
            $finish;
        end

        $display("Generation 1 passed");

        //Generation 2
        @(negedge clk);
        generation_tick = 1'b1;

        @(negedge clk);
        generation_tick = 1'b0;

        #1;

        // After two gens, the normal blinker should return to initial vertical pattern
        if (blinker_alive !== 64'h0000000808080000) begin
            $display("Fail: incorrect pattern");
            $finish;
        end

        // wraparound blinker should also be vertical now
        if (wrap_alive !== 64'h0100000000000101) begin
            $display("Fail: incorrect pattern");
            $finish;
        end

        $display("Generation 2 passed");
        $display("Pass: Rules verified :)");

        // End the simulation
        $finish;

    end

endmodule