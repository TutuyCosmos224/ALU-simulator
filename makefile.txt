PROG = test_ALU

CC = iverilog

EXE = vvp

$(PROG): $(PROG).v
	$(CC) -o $(PROG).vvp $(PROG).v
	$(EXE) $(PROG).vvp

clean:
	rm $(PROG)
		 