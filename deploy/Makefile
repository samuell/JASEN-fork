# ==============================================================================
# Define variables etc
# ==============================================================================
# Make sure bash is used as shell, for consistency
SHELL := /bin/bash

# Define path variables
SCRIPT_DIR := $(shell pwd)
ASSETS_DIR := $(shell realpath $(SCRIPT_DIR)/../assets/)
CONTAINER_DIR := $(realpath $(SCRIPT_DIR)/../container/)
# The root folder where the pipeline is currently located. To be mounted into
# the Singularity containers below.
MNT_ROOT := /$(shell readlink -f . | cut -d"/" -f2)
INSTALL_LOG := $(SCRIPT_DIR)"/.install.log"

.PHONY: print_vars install update_amrfinderplus update_mlst_db update_blast_db

define log_message
	@echo "--------------------------------------------------------------------------------" >> $(INSTALL_LOG)
	@echo $(shell date "+%Y-%m-%d %H:%M:%S"): $1 >> $(INSTALL_LOG)
	@echo "--------------------------------------------------------------------------------" >> $(INSTALL_LOG)
endef

# ==============================================================================
# Main rules
# ==============================================================================

print_paths:
	@echo "SCRIPT_DIR:" $(SCRIPT_DIR)
	@echo "ASSETS_DIR:" $(ASSETS_DIR)
	@echo "CONTAINER_DIR:" $(CONTAINER_DIR)
	@echo "MNT_ROOT:" $(MNT_ROOT)

install: update_amrfinderplus update_mlst_db update_blast_db

# ==============================================================================
# Update databases
# ==============================================================================

# -----------------------------
# Update AMRFinderPlus database
# -----------------------------
# For more info, see:
# https://www.ncbi.nlm.nih.gov/pathogens/antimicrobial-resistance/AMRFinder/
update_amrfinderplus: $(ASSETS_DIR)/amrfinder_db/latest

$(ASSETS_DIR)/amrfinder_db/latest:
	$(call log_message,"Starting update of AMRFinderPlus database")
	singularity exec \
		--bind $(MNT_ROOT) \
		$(CONTAINER_DIR)/amrfinderplus.sif \
		amrfinder_update \
		--database $(ASSETS_DIR)/amrfinder_db &>> $(INSTALL_LOG)

# -----------------------------
# Update MLST database
# -----------------------------
update_mlst_db: $(ASSETS_DIR)/mlst_db/pubmlst/dbases.xml

$(ASSETS_DIR)/mlst_db/pubmlst/dbases.xml:
	$(call log_message,"Starting update of MLST database")
	cd $(ASSETS_DIR)/mlst_db \
	&& bash mlst-download_pub_mlst.sh &>> $(INSTALL_LOG)

# -----------------------------
# Update Blast database
# -----------------------------
update_blast_db: $(ASSETS_DIR)/mlst_db/blast

$(ASSETS_DIR)/mlst_db/blast:
	$(call log_message,"Starting update of Blast database")
	cd $(ASSETS_DIR)/mlst_db \
	&& singularity exec \
		--bind $(MNT_ROOT) \
		$(CONTAINER_DIR)/blast.sif \
		bash $(ASSETS_DIR)/mlst_db/mlst-make_blast_db.sh &>> $(INSTALL_LOG)
