module counter (
    // peripheral clock signals
    input          clk,
    input          rst_n,
    // register facing signals
    output  [15:0] count_val,
    input   [15:0] period,
    input          en,
    input          count_reset,
    input          upnotdown,
    input   [7:0]  prescale
);

    // Registre interne
    reg [15:0] count_val_r;
    reg [7:0]  prescale_cnt;

    // Conectam registrul intern la iesire
    assign count_val = count_val_r;

    // Logica principala
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset asincron (Hardware Reset)
            count_val_r  <= 16'd0;
            prescale_cnt <= 8'd0;
        end else begin
            if (count_reset) begin
                // Reset sincron (din Software/Registru)
                count_val_r  <= 16'd0;
                prescale_cnt <= 8'd0;
            end else if (en) begin
                // Logica de Prescaler (Liniar: Divide cu prescale + 1)
                if (prescale_cnt == prescale) begin
                    // Prescaler a atins limita, executam un "tick" de numarare
                    prescale_cnt <= 8'd0;

                    if (upnotdown) begin
                        // UP MODE: 0 -> period
                        if (count_val_r == period)
                            count_val_r <= 16'd0;
                        else
                            count_val_r <= count_val_r + 1'b1;
                    end else begin
                        // DOWN MODE: period -> 0
                        if (count_val_r == 0)
                            count_val_r <= period;
                        else
                            count_val_r <= count_val_r - 1'b1;
                    end
                end else begin
                    // Inca nu a trecut timpul, incrementam prescalerul
                    prescale_cnt <= prescale_cnt + 1'b1;
                end
            end
        end
    end

endmodule