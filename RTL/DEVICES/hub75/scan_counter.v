module scan_counter(
    input  wire clk,
    input  wire rst,

    output reg [5:0] col,
    output reg [4:0] scan_row,
    output reg [4:0] addr_out,
    output reg [4:0] pwm_level,

    output wire [5:0] row_top,
    output wire [5:0] row_bottom
);

    always @(posedge clk) begin
        if (rst) begin
            col <= 0;
            scan_row <= 0;
            addr_out <= 0;
            pwm_level <= 0;
        end else begin
            col <= col + 1;
            if (col == 63) begin
                col <= 0;
            end

            if (col == 0) begin
                addr_out <= scan_row - 5'd1;
            end

            // Advance the image row only after scanning the final column.
            if (col == 63) begin
                scan_row <= scan_row + 1;
                if (scan_row == 31) begin
                    scan_row <= 0;
                    pwm_level <= pwm_level + 1;
                end
            end
        end
    end

    // There is not need of 1'b0. It's basically 0.
    // assign row_top    = {1'b0, scan_row};
    assign row_top    = scan_row;
    assign row_bottom = {1'b1, scan_row};

endmodule
