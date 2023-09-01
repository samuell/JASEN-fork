# Make sure bash is used as shell, for consistency
SHELL := /bin/bash

# Define path variables
SCRIPT_DIR := $(shell pwd)
ASSETS_DIR := $(shell realpath $(SCRIPT_DIR)/../assets/)
CONTAINER_DIR := $(realpath $(SCRIPT_DIR)/../container/)
# The root folder where the pipeline is currently located. To be mounted into
# the Singularity containers below.
MNT_ROOT := /$(shell readlink -f . | cut -d"/" -f2)

.PHONY: print_vars update_amrfinderplus update_mlst_db update_blast_db

print_paths:
	@echo "SCRIPT_DIR:" $(SCRIPT_DIR)
	@echo "ASSETS_DIR:" $(ASSETS_DIR)
	@echo "CONTAINER_DIR:" $(CONTAINER_DIR)
	@echo "MNT_ROOT:" $(MNT_ROOT)

# ------------------------------------------------------------------------------
#  Databases
# ------------------------------------------------------------------------------

# -----------------------------
# Update AMRFinderPlus database
# -----------------------------
# For more info, see:
# https://www.ncbi.nlm.nih.gov/pathogens/antimicrobial-resistance/AMRFinder/
update_amrfinderplus: ../assets/amrfinder_db/latest

../$(ASSETS_DIR)/amrfinder_db/latest:
	singularity exec \
		--bind $(MNT_ROOT) \
		$(CONTAINER_DIR)/amrfinderplus.sif \
		amrfinder_update \
		--database $(ASSETS_DIR)/amrfinder_db

# -----------------------------
# Update MLST database
# -----------------------------
update_mlst_db: ../$(ASSETS_DIR)/mlst_db/pubmlst

../$(ASSETS_DIR)/mlst_db/pubmlst:
	cd $(ASSETS_DIR)/mlst_db \
	&& bash mlst-download_pub_mlst.sh &> /dev/null \

# -----------------------------
# Update Blast database
# -----------------------------
update_blast_db: ../$(ASSETS_DIR)/mlst_db/blast

../$(ASSETS_DIR)/mlst_db/blast:
	cd $(ASSETS_DIR)/mlst_db \
	&& singularity exec \
		--bind $(MNT_ROOT) \
		$(CONTAINER_DIR)/blast.sif \
		bash $(ASSETS_DIR)/mlst_db/mlst-make_blast_db.sh &> /dev/null
