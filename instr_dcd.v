module instr_dcd (
    // peripheral clock signals
    input clk,
    input rst_n,
    // towards SPI slave interface signals
    input byte_sync,
    input [7:0] data_in,
    output [7:0] data_out,
    // register access signals
    output read,
    output write,
    output [5:0] addr,
    input [7:0] data_read,
    output [7:0] data_write
);
    // registri pentru outputuri
    reg r_read;
    reg r_write;
    reg [5:0] r_addr;
    reg [7:0] r_data_write;

    // legam iesirile
    assign read = r_read;
    assign write = r_write;
    assign addr = r_addr;
    assign data_write = r_data_write;

    assign data_out = (r_read) ? data_read : 8'h00;

    // logica de FSM
    reg state;
    reg next_state;
    reg is_read_op;

    // selectia pentru MSB/LSB
    reg byte_sel;

    // adresa de baza (fara bitul 6)
    reg [5:0] base_addr;

    localparam ST_SETUP = 0;
    localparam ST_DATA = 1;

    always @(*) begin
        next_state = state;
        case (state)
            ST_SETUP: begin
                if (byte_sync) next_state = ST_DATA;
            end
            ST_DATA: begin
                if (byte_sync) next_state = ST_SETUP;
            end
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state <= ST_SETUP;
            r_read <= 0;
            r_write <= 0;
            r_addr <= 0;
            r_data_write <= 0;
            is_read_op <= 0;
            base_addr <= 0;
            byte_sel <= 0;
        end
        else begin
            r_write <= 0; // trebuie resetat la 0 la fiecare ciclu, il setam la 1 doar cand vrem

            if(byte_sync) begin
                case(state)
                    ST_SETUP: begin
                        // bitul 7: 1 = write, 0 = read
                        is_read_op <= (data_in[7] == 0);

                        // bitul 6: MSB/LSB select
                        byte_sel <= data_in[6];

                        // bits 5:0 = adresa
                        base_addr <= data_in[5:0];

                        // pt READ: calculam adresa cu offset imediat
                        // pt WRITE: folosim adresa de baza (offset-ul se aplica in DATA)
                        if (data_in[7] == 0) begin
                            // READ operation - calculam adresa cu offset
                            r_addr <= data_in[5:0] + (data_in[6] ? 6'd1 : 6'd0);
                        end else begin
                            // WRITE operation - adresa de baza
                            r_addr <= data_in[5:0];
                        end

                        // setam r_read
                        r_read <= (data_in[7] == 0);

                        state <= ST_DATA;
                    end

                    ST_DATA: begin
                        // Pentru WRITE, calculam adresa efectiva acum
                        if(!is_read_op) begin
                            r_addr <= base_addr + (byte_sel ? 6'd1 : 6'd0);
                            // daca e scriere, luam datele primite si le trimitem la registrii
                            r_data_write <= data_in;
                            r_write <= 1; // activam write mode
                        end

                        // dupa faza de date, dezactivam citirea
                        r_read <= 0;

                        state <= ST_SETUP;
                    end
                endcase
            end
        end
    end

endmodule
