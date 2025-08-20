# pre-synthesis simulation
vcs -R grayscale_tb.v -full64 -debug_access+all
#vcs -R grayscale_tb.v -full64 +define+FSDB -debug_access+all

# post-synthesis simulation
#vcs -R grayscale_tb.v -full64 +define+SYN -debug_access+all
#vcs -R grayscale_tb.v -full64  +define+FSDB+SYN -debug_access+all