`timescale 1ns/1ps

module tb_{{DUT_MODULE}};
    localparam real CLK_PERIOD_NS = {{CLK_PERIOD_NS}};

    reg clk;
    reg rst_n;

    // TODO: declare DUT input/output signals.
    // Example:
    // reg  [15:0] in_data;
    // reg         in_valid;
    // wire [15:0] out_data;
    // wire        out_valid;

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD_NS / 2.0) clk = ~clk;
    end

    initial begin
        rst_n = 1'b0;
        repeat ({{RESET_CYCLES}}) @(posedge clk);
        rst_n = 1'b1;
    end

    {{DUT_MODULE}} dut (
        .clk   (clk),
        .rst_n (rst_n)
        // TODO: connect remaining DUT ports.
    );

    initial begin
        // TODO: initialize input signals.
        wait (rst_n === 1'b1);
        repeat ({{STIMULUS_CYCLES}}) begin
            @(posedge clk);
            // TODO: drive stimulus.
        end

        repeat ({{DRAIN_CYCLES}}) @(posedge clk);
        $display("TB_PASS: simulation completed");
        $finish;
    end

    initial begin
        if ("{{VCD_FILE}}" != "") begin
            $dumpfile("{{VCD_FILE}}");
            $dumpvars(0, tb_{{DUT_MODULE}});
        end
    end

    initial begin
        #({{TIMEOUT_NS}});
        $display("TB_ERROR: timeout");
        $finish;
    end
endmodule
