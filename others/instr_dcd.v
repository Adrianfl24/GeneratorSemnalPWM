module instr_dcd (
    // peripheral clock signals
    input clk,
    input rst_n,
    // towards SPI slave interface signals
    input byte_sync,
    input[7:0] data_in,
    output[7:0] data_out,
    // register access signals
    output read,
    output write,
    output[5:0] addr,
    input[7:0] data_read,
    output[7:0] data_write
);
    // registri pentru outputuri
    reg r_read;
    reg r_write;
    reg [5:0] r_addr;
    reg [7:0] r_data_write;
    reg [7:0] r_data_out;

    // legam iesirile
    assign read = r_read;
    assign write = r_write;
    assign addr = r_addr;
    assign data_write = r_data_write;
    assign data_out = r_data_out;

    // logica de FSM
    reg state; // starea curenta
    reg next_state;
    // 0 = SETUP
    // 1 = DATA
    reg is_read_op; // registru care stocheaza daca informatia este de citire

    localparam ST_SETUP = 0;
    localparam ST_DATA  = 1;

    always @(*) begin
        next_state = state;
        case (state)
            ST_SETUP: begin
                if (byte_sync)
                    next_state = ST_DATA;
            end

            ST_DATA: begin
                if (byte_sync)
                    next_state = ST_SETUP;
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
            r_data_out <= 0;
            is_read_op <= 0;
        end
        else begin
            r_write <= 0; // trebuie resetat la 0 la fiecare ciclu, il setam la 1 doar cand vrem

            // semnalul de read il resetam doar daca am terminat operatia
            // altfel ramane activ
            if(state == ST_SETUP) begin
                r_read <= 0;
            end

            if(byte_sync) begin
                case(state)
                    ST_SETUP: begin
                        // bitul 7: 1 = write, 0 = read
                        is_read_op <= (data_in[7] == 0);

                        // calculul adresei
                        // daca bitul 6 e 1, inseamna byte-ul de sus -> adresa + 1
                        // daca e 0 -> byte-ul de jos -> adresa + 0
                        r_addr <= data_in[5:0] + (data_in[6] ? 6'd1 : 6'd0);

                        // trecem in faza de date
                        state <= ST_DATA;

                        // Daca este CITIRE, trebuie sa activam 'read' ACUM.
                        // Astfel, in urmatorul ciclu, modulul de regiștri ne va da datele in 'data_read',
                        // iar noi le vom avea gata pentru SPI cand incepe sa trimita byte-ul 2.
                        if(data_in[7] == 0) begin
                            r_read <= 1;
                        end
                    end

                    ST_DATA: begin
                        if(!is_read_op) begin
                            // daca e scriere, luam datele primite si le trimitem la registrii
                            r_data_write <= data_in;
                            r_write <= 1; // activam write mode
                        end else begin
                            r_data_out <= data_read;
                        end

                        state <= ST_SETUP;
                        r_read <= 0;
                    end
                endcase
            end


        end
    end

endmodule
