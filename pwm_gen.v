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
    wire align_mode = functions[1]; // 0 = aliniat, 1 = nealiniat
    wire align_right = functions[0]; // 0 = left, 1 = right

    reg r_pwm;

    always @(*) begin
        if (!pwm_en) begin
            r_pwm = 1'b0;
        end else begin
            if (!align_mode) begin
                if (count_val < compare1) begin
                    // inainte de compare1
                    r_pwm = (align_right ? 1'b0 : 1'b1);
                end else begin
                    // la sau dupa compare1 (inclusiv)
                    r_pwm = (align_right ? 1'b1 : 1'b0);
                end
            end else begin
                if (count_val < compare1) begin
                    r_pwm = 1'b0;
                end else if (count_val < compare2) begin
                    r_pwm = 1'b1;
                end else begin
                    r_pwm = 1'b0;
                end
            end
        end
    end

    assign pwm_out = r_pwm;
endmodule
