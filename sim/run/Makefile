FILELIST_DIR := ./filelist.f
GOWIN_SIM_LIB := ../lib/prim_sim.v
.PHONY: all vcs clear
all: 
	@make vcs
	@make verdi
vcs:
	@vcs -full64 -lca -sverilog +v2k \
	  -LDFLAGS -Wl,--no-as-needed \
	  -v $(GOWIN_SIM_LIB) \
	  -f $(FILELIST_DIR) \
	  -R +vc -fsdb +define+FSDB +fsdb+force -debug_access -pcmakeprof | tee vcs.log
verdi:
	@fsdb_files=$(wildcard *.fsdb); \
	rc_files=$(wildcard signal.rc); \
	if [ -n "$$fsdb_files" ]; then \
		if [ -n "$$rc_files" ]; then \
			verdi -sv -nologo -f $(FILELIST_DIR) $(GOWIN_SIM_LIB) -ssf $$fsdb_files -sswr $$rc_files & \
		else \
			verdi -sv -nologo -f $(FILELIST_DIR) $(GOWIN_SIM_LIB) -ssf $$fsdb_files & \
		fi \
	fi
clear:
	@rm -rf ./csrc novas* *.daidir *.log simv* *.key *.fsdb ./verdiLog
	@echo "clear done!"
