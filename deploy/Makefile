# Define variables
SCRIPT_DIR := $(shell pwd)
ASSETS_DIR := $(shell realpath $(SCRIPT_DIR)/../assets/)
CONTAINER_DIR := $(realpath $(SCRIPT_DIR)/../container/)

# The root folder where the pipeline is currently located. To be mounted into
# the Singularity containers below.
MNT_ROOT := /$(shell readlink -f . | cut -d"/" -f2)

.PHONY: print_vars update_amrfinderplus

print_vars:
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
../assets/amrfinder_db/latest:
	singularity exec \
		--bind $(MNT_ROOT) \
		$(CONTAINER_DIR)/amrfinderplus.sif amrfinder_update \
		--database $(ASSETS_DIR)/amrfinder_db
