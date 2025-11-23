module pwm_gen (
    // peripheral clock signals
    input clk,
    input rst_n,
    // PWM signal register configuration
    input pwm_en,
    input[15:0] period,
    input[7:0] functions,
    input[15:0] compare1,
    input[15:0] compare2,
    input[15:0] count_val,
    // top facing signals
    output pwm_out
);
    reg r_pwm;
    assign pwm_out = r_pwm;

    wire align_mode = functions[1]; // 0 = aliniat, 1 = nealiniat
    wire align_right = functions[0]; // 0 = left, 1 = right

    // logica pwm
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            r_pwm <= 1'b0;
        end else begin
            // daca pwm e dezactivat, nu schimbam iesirea
            if (!pwm_en) begin
                r_pwm <= r_pwm; // ramane blocat
            end else begin

                if(!align_mode) begin
                    if(count_val == 16'd0) begin
                        // mod alinmiat
                        // left aligned -> incepe pe 1
                        // right aligned -> incepe pe 0
                        r_pwm <= (align_right ? 1'b0 : 1'b1);
                    end else if (count_val == compare1) begin
                        r_pwm <= ~r_pwm;
                    end
                end
                else begin
                    // mod nealiniat -> incepe mereu pe 0
                    if (count_val == 0) begin
                        r_pwm <= 1'b0;
                    end
                    // mod nealiniat
                    // 0 trece in 1 la compare1
                    // 1 trece in 0 la compare2
                    else if (count_val == compare1) begin
                        r_pwm <= 1'b1;
                    end
                    else if (count_val == compare2) begin
                        r_pwm <= 1'b0;
                    end
                end
            end
        end
    end
endmodule
