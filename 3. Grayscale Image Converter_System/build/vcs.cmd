### Compile & Simulation ###
#vcs -R -sverilog ../sim/testbench.sv -full64 +define+P1 -debug_access+all
#vcs -R -sverilog ../sim/testbench.sv -full64 +define+P2 -debug_access+all
vcs -R -sverilog ../sim/testbench.sv  -full64 +define+TEST -debug_access+all

### Debug with waveform ###
#vcs -R -sverilog ../sim/testbench.sv -full64 +define+P1+FSDB -debug_access+all
#vcs -R -sverilog ../sim/testbench.sv -full64 +define+P2+FSDB -debug_access+all
#vcs -R -sverilog ../sim/testbench.sv -full64 +define+TEST+FSDB -debug_access+all

### Debug with waveform & memory ###
#vcs -R -sverilog ../sim/testbench.sv -full64 +define+P1+FSDB_ALL -debug_access+all
#vcs -R -sverilog ../sim/testbench.sv -full64 +define+P2+FSDB_ALL -debug_access+all
#vcs -R -sverilog ../sim/testbench.sv -full64 +define+TEST+FSDB_ALL -debug_access+all

### Logic Synthesis ###
#dc_shell -f ../script/synthesis.tcl

### Compile & Simulation After Synthesize ###
#vcs -R -sverilog ../sim/testbench.sv -full64 +define+P1+SYN -debug_access+all
#vcs -R -sverilog ../sim/testbench.sv -full64 +define+P2+SYN -debug_access+all
#vcs -R -sverilog ../sim/testbench.sv -full64 +define+TEST+SYN -debug_access+all
