module next_gen #(
    parameter SEED_FILE = "seed.memh" // load seed memory file
) (
    input  logic        clk,
    input  logic        generation_tick,
    output logic [63:0] alive
);

    logic [63:0] seed_mem [0:0];
    logic [63:0] next_alive;

    integer current_column; // current cell's column, from 0 to 7
    integer current_row; // current cell's row, from 0 to 7
    integer hor_offset; // horizontal neighbor offset: -1, 0, or 1
    integer ver_offset; // vertical neighbor offset: -1, 0, or 1
    integer wrapped_column; // wrapped neighbor column
    integer wrapped_row; // wrapped neighbor row
    integer neighbors;

    initial begin
        $readmemh(SEED_FILE, seed_mem); // read initial pattern file
        $display("Loaded seed file %s: %h", SEED_FILE, seed_mem[0]);
    end

    // check if initial seed loaded
    logic initialized = 1'b0;

    // calculate next grid
    always_comb begin
        next_alive = 64'b0; // begin with every next-gen being dead
        // temp values
        neighbors = 0;
        wrapped_column = 0;
        wrapped_row = 0;

        // visit each row of the grid
        for (current_row = 0; current_row < 8; current_row = current_row + 1) begin
            // visit each column in the current row
            for (current_column = 0; current_column < 8; current_column = current_column + 1) begin
                neighbors = 0; // start fresh neighbor count
                // check above and below
                for (ver_offset = -1; ver_offset <= 1; ver_offset = ver_offset + 1) begin
                    // check left and right
                    for (hor_offset = -1; hor_offset <= 1; hor_offset = hor_offset + 1) begin
                        // skip current cell
                        if ((hor_offset != 0) || (ver_offset != 0)) begin
                            // calculate neighbor's column
                            wrapped_column = (current_column + hor_offset + 8) % 8;
                            // calculate neighbors row
                            wrapped_row = (current_row + ver_offset + 8) % 8;
                            // add one if the neighboring cell is alive
                            neighbors = neighbors + alive[wrapped_row * 8 + wrapped_column];
                        end
                    end
                end

                // live cell survives with 2 or 3 live neighbors
                if (alive[current_row * 8 + current_column]) begin
                    next_alive[current_row * 8 + current_column] =
                        (neighbors == 2) || (neighbors == 3);
                end else begin
                    // if current cell is dead, it becomes alive with three living neighbors
                    next_alive[current_row * 8 + current_column] = (neighbors == 3);
                end
            end
        end
    end

    // Update all 64 cells simultaneously on a generation_tick
    always_ff @(posedge clk) begin
        if (!initialized) begin
            alive <= seed_mem[0];
            initialized <= 1'b1;
        end else if (generation_tick) begin
            alive <= next_alive;
        end
    end

endmodule
