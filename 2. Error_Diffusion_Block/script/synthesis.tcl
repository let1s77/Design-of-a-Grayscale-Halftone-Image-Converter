#   Read in top module
read_file -format verilog ../src/error_diffusion.v
current_design error_diffusion
link
#   Set Design Environment
source ../script/DC.sdc
check_design
#   Synthesize circuit
 compile -map_effort medium -area_effort medium
#compile -map_effort high -area_effort high

#   Create Report
#timing report(setup time)
report_timing -path full -delay max -nworst 1 -max_paths 1 -significant_digits 2 -sort_by group > ../syn/timing_max_rpt.txt
#timing report(holf time)
report_timing -path full -delay min -nworst 1 -max_paths 1 -significant_digits 2 -sort_by group > ../syn/timing_min_rpt.txt
#area report
report_area -nosplit > ../syn/area_rpt.txt
#report power
report_power -analysis_effort low > ../syn/power_rpt.txt
#   Save syntheized file
write -hierarchy -format verilog -output {../syn/error_diffusion_syn.v}
write_sdf -version 1.0 -context verilog {../syn/error_diffusion_syn.sdf}
exit
