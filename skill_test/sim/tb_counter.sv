`timescale 1ns/1ps

module tb_counter;
    reg clk;
    reg rst_n;
    reg en;
    wire [7:0] count;
    integer i;

    counter #(.WIDTH(8)) dut (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .count(count)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst_n = 1'b0;
        en = 1'b0;
        repeat (3) @(posedge clk);
        rst_n = 1'b1;
        en = 1'b1;

        for (i = 0; i < 16; i = i + 1) begin
            @(posedge clk);
            #1;
            if (count !== (i + 1)) begin
                $display("TB_ERROR: expected %0d got %0d", i + 1, count);
                $finish;
            end
        end

        $display("TB_PASS: counter simulation completed");
        $finish;
    end
endmodule
