module alu(instruction, regA, regB, result, flags);

    input[31:0] instruction, regA, regB;
    output [31:0] result;
    output [2:0] flags;

    reg[5:0] opcode, func;

    reg[31:0] reg_result;        //storing the result of the instruction

    reg[2:0] reg_flags;     //storing the flag values

    parameter gr0 = 32'h0000_0000;

    reg[31:0] rs, rt;       //storing the inputs

    always @(instruction, regA, regB) begin

        /* parsing the instruction */
        assign func = instruction[5:0];
        assign opcode = instruction[31:26];

        /* assign rs register */
        if (instruction[25:21] == 5'b00000) rs = regA;
        else if (instruction[25:21] == 5'b00001) rs = regB;
        else rs = 0;

        /* assign rt register */
        if(instruction[20:16] == 5'b00000) rt = regA;
        else if (instruction[20:16] == 5'b00001) rt = regB;
        else rt = 0;

        reg_flags = 3'b000;

        case(opcode)
            /* R-Type */
            6'b000000: begin  
                case(func)
                    6'b100000: begin //Add
                        reg_result = rs + rt;

                        if (reg_result[30:0] == 0) begin
                                reg_flags[0] = 1'b1;
                        end
                            
                        if (reg_result[31] == 0) begin
                                if (rs[31] == 1 & rt[31] == 1) reg_flags[2] = 1'b1;
                        end
                        else if (reg_result[31] == 1) begin
                                if (rs[31] == 0 & rt[31] == 0) reg_flags[2] = 1'b1;
                        end
                            
                        if(reg_result[31] == 1) reg_flags[1] = 1'b1;
                    end
                    
                    6'b100001:  reg_result = rs + rt; //Addu

                    6'b100010: begin //sub
                        reg_result = rs - rt;

                        if (reg_result[30:0] == 0) begin
                                reg_flags[0] = 1'b1;
                        end

                        if(rs[31] == 0 & rt[31] == 0) begin
                            if(reg_result[31] == 0) reg_flags[0] = 1'b1;
                            else if (rt < rs) reg_flags[1] = 1'b1;
                        end

                        else if(rs[31] == 1 & rt[31] == 1) begin
                            if(reg_result[31] == 0) reg_flags[0] = 1'b1;
                            else if (rt > rs) reg_flags[1] = 1'b1;
                        end

                        else if(rs[31] == 1 & rt[31] == 0) begin
                            reg_flags[1] = 1'b1;
                            if (reg_result[31] == 0) reg_flags[2] = 1'b1;  
                        end

                        else if(rs[31] == 0 & rt[31] == 1) begin
                            if (reg_result[31] == 1) reg_flags[2] = 1'b1;  
                        end

                    end

                    6'b100011: reg_result = rs - rt; //Subu 

                    6'b000000: reg_result = rt << instruction[10:6]; //Sll 

                    6'b000100: reg_result = rt << rs; //Sllv 

                    6'b000010: reg_result = rt >> instruction[10:6]; //Srl 

                    6'b000110: reg_result = rt >> rs; //Srlv 

                    6'b000011: reg_result = rt >>> instruction[10:6]; //Sra 

                    6'b000111: reg_result = rt >>> rs; //Srav 

                    6'b100100: reg_result = rs & rt; //And 

                    6'b100111: reg_result = ~(rs | rt); //Nor 

                    6'b100101: reg_result = rs | rt; //Or 

                    6'b100110: reg_result = rs ^ rt; //Xor 

                    6'b101010: begin //Slt
                        if ($signed(rs) < $signed(rt)) reg_result = 1;
                        else reg_result = 0;

                        if (reg_result == 1) reg_flags[1] = 1'b1;  
                    end

                    6'b101011: begin //Sltu
                        if (rs < rt) reg_result = 1;
                        else reg_result = 0;

                        if (reg_result == 1) reg_flags[1] = 1'b1;  
                    end
                endcase
            end

            /* I_type */
            6'b001000: begin //Addi instruction
                reg_result = rs + {{16{instruction[15]}},instruction[15:0]};
                if (reg_result[30:0] == 0) begin
                                reg_flags[0] = 1'b1;
                        end
                            
                        if (reg_result[31] == 0) begin
                                if (rs[31] == 1 & rt[31] == 1) reg_flags[2] = 1'b1;
                        end
                        else if (reg_result[31] == 1) begin
                                if (rs[31] == 0 & rt[31] == 0) reg_flags[2] = 1'b1;
                        end
                            
                        if(reg_result[31] == 1) reg_flags[1] = 1'b1;
            end

            6'b001001: reg_result = rs + {{16{instruction[15]}}, instruction[15:0]}; //Addiu

            6'b001100: reg_result = rs & {{16{1'b0}},instruction[15:0]}; //Andi

            6'b001101: reg_result = rs | {{16{1'b0}},instruction[15:0]}; //Ori

            6'b001110: reg_result = rs ^ {{16{1'b0}},instruction[15:0]}; //Xori

            6'b000100: begin //Beq
                reg_result = $signed(rs) - $signed(rt);
                
                if (reg_result == 0) reg_result = instruction[15:0];
                else begin
                    reg_result = 0;
                    reg_flags = 1'b1;
                end
            end

            6'b000101: begin //Bne
                reg_result = $signed(rs) - $signed(rt);
                
                if (reg_result != 0) reg_result = instruction[15:0];
                else begin
                    reg_result = 0;
                    reg_flags = 1'b1;
                end
            end

            6'b001010: begin //Slti
                if ($signed(rs) < $signed({{16{instruction[15]}}, instruction[15:0]})) reg_result = 1;
                else reg_result = 0;

                if (reg_result == 1) reg_flags[1] = 1'b1;

            end

            6'b001011: begin //Sltiu
                if (rs < {{16{instruction[15]}}, instruction[15:0]}) reg_result = 1;
                else reg_result = 0;

                if (reg_result == 1) reg_flags[1] = 1'b1;
            end

            6'b100011: reg_result = $signed(rt) + $signed({{16{instruction[15]}}, instruction[15:0]}); //Lw

            6'b101011: reg_result = $signed(rs) + $signed({{16{instruction[15]}}, instruction[15:0]}); //Sw

        endcase
    end
    
    assign flags = reg_flags;
    assign result = reg_result;

endmodule //alu 