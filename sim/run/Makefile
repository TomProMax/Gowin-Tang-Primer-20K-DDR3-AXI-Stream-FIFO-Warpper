.PHONY: all vcs clear clean help

FILELIST_DIR := ./filelist.f
GOWIN_SIM_LIB := ../lib/prim_sim.v

SEED := 1

all: 
	@make vcs
	@make verdi

vcs:
	@vcs -full64 -lca -sverilog +v2k \
	  -LDFLAGS -Wl,--no-as-needed \
	  -v $(GOWIN_SIM_LIB) \
	  -f $(FILELIST_DIR) \
	  +ntb_random_seed=$(SEED) \
	  -R +vc -fsdb +define+FSDB +fsdb+force -debug_access -pcmakeprof -nc | tee vcs.log

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

clean:
	@make clear

clear:
	@rm -rf ./csrc novas* *.daidir *.log simv* *.key *.fsdb ./verdiLog
	@echo "clear done!"

help:
	@echo "use 'make vcs SEED=\$$(SEED)' to compile and run simulation"
	@echo "use 'make verdi' to view the waveform"