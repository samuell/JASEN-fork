# Define variables
SCRIPT_DIR := $(shell pwd)
ASS_DIR := $(realpath $(SCRIPT_DIR)/../assets/)
CONTAINER_DIR := $(realpath $(SCRIPT_DIR)/../container/)

# The root folder where the pipeline is currently located. To be mounted into
# the Singularity containers below.
MNT_ROOT := /$(shell readlink -f . | cut -d"/" -f2)

.PHONY: print_vars

print_vars:
	@echo "SCRIPT_DIR:" $(SCRIPT_DIR)
	@echo "ASS_DIR:" $(ASS_DIR)
	@echo "CONTAINER_DIR:" $(CONTAINER_DIR)
	@echo "MNT_ROOT:" $(MNT_ROOT)

# ------------------------------------------------------------------------------
#  Databases
# ------------------------------------------------------------------------------

