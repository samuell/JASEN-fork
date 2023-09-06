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
INSTALL_LOG := "$(SCRIPT_DIR)/.install.log"

.PHONY: print_vars install update_amrfinderplus update_mlst_db update_blast_db update_virulencefinder_db

define log_message
	@echo "--------------------------------------------------------------------------------" | tee -a $(INSTALL_LOG);
	@echo "$$(date "+%Y-%m-%d %H:%M:%S"): $1" | tee -a $(INSTALL_LOG);
	@echo "--------------------------------------------------------------------------------" | tee -a $(INSTALL_LOG);
endef

# ==============================================================================
# Main rules
# ==============================================================================

print_paths:
	@echo "SCRIPT_DIR:" $(SCRIPT_DIR)
	@echo "ASSETS_DIR:" $(ASSETS_DIR)
	@echo "CONTAINER_DIR:" $(CONTAINER_DIR)
	@echo "MNT_ROOT:" $(MNT_ROOT)

install: update_amrfinderplus update_mlst_db update_blast_db update_virulencefinder_db

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

# -----------------------------
# Update VirulenceFinder database
# -----------------------------
update_virulencefinder_db: $(ASSETS_DIR)/virulencefinder_db/stx.name

$(ASSETS_DIR)/virulencefinder_db/stx.name:
	$(call log_message,"Starting update of VirulenceFinder database")
	cd $(ASSETS_DIR)/kma \
	&& make \
	&& cd $(ASSETS_DIR)/virulencefinder_db \
	&& export PATH=$(ASSETS_DIR)/kma:$$PATH \
	&& singularity exec	--bind $(MNT_ROOT) $(CONTAINER_DIR)/pythonScripts.sif \
		python3 INSTALL.py \
		$(ASSETS_DIR)/kma/kma_index \
	&& cd $(ASSETS_DIR)/resfinder_db \
	&& singularity exec --bind $(MNT_ROOT) $(CONTAINER_DIR)/pythonScripts.sif \
		python3 INSTALL.py \
		$(ASSETS_DIR)/kma/kma_index \
	&& cd $(ASSETS_DIR)/pointfinder_db \
	&& singularity exec --bind $(MNT_ROOT) $(CONTAINER_DIR)/pythonScripts.sif \
		python3 INSTALL.py \
		$(ASSETS_DIR)/kma/kma_index

# ==============================================================================
# Download, index and prep reference genomes for organisms
# ==============================================================================

# -----------------------------
# S. Aureus
# -----------------------------
#.PHONY: saureus_all saureus_download_reference saureus_index_reference saureus_download_cgmlst_schema saureus_unpack_cgmlst_schema saureus_prep_cgmlst_schema

saureus_all: saureus_download_reference \
	saureus_index_reference \
	saureus_download_cgmlst_schema \
	saureus_unpack_cgmlst_schema \
	saureus_prep_cgmlst_schema

saureus_download_reference: $(ASSETS_DIR)/genomes/staphylococcus_aureus/NC_002951.2.fasta

$(ASSETS_DIR)/genomes/staphylococcus_aureus/NC_002951.2.fasta:
	$(call log_message,"Downloading S. Aureus reference genome ...")
	mkdir -p $(ASSETS_DIR)/genomes/staphylococcus_aureus \
	&& cd $(ASSETS_DIR)/.. \
	&& singularity exec --bind $(MNT_ROOT) $(CONTAINER_DIR)/pythonScripts.sif \
		python3 bin/download_ncbi.py \
		-i NC_002951.2 \
		-o $(ASSETS_DIR)/genomes/staphylococcus_aureus


saureus_index_reference: $(ASSETS_DIR)/genomes/staphylococcus_aureus/NC_002951.2.fasta.bwt

$(ASSETS_DIR)/genomes/staphylococcus_aureus/NC_002951.2.fasta.bwt: $(ASSETS_DIR)/genomes/staphylococcus_aureus/NC_002951.2.fasta
	$(call log_message,"Indexing S. Aureus reference genome ...")
	cd $(ASSETS_DIR)/genomes/staphylococcus_aureus \
	&& singularity exec --bind $(MNT_ROOT) $(CONTAINER_DIR)/bwakit.sif \
		bwa index NC_002951.2.fasta


saureus_download_cgmlst_schema: $(ASSETS_DIR)/cgmlst/staphylococcus_aureus/alleles/cgmlst_141106.zip

$(ASSETS_DIR)/cgmlst/staphylococcus_aureus/alleles/cgmlst_141106.zip:
	$(call log_message,"Downloading S. Aureus cgMLST schema ...")
	mkdir -p $(ASSETS_DIR)/cgmlst/staphylococcus_aureus/alleles &> /dev/null \
	&& cd $(ASSETS_DIR)/cgmlst/staphylococcus_aureus/alleles \
	&& wget https://www.cgmlst.org/ncs/schema/141106/alleles/ \
		-O $@ \
		--no-check-certificate &> /dev/null \


saureus_unpack_cgmlst_schema: $(ASSETS_DIR)/cgmlst/staphylococcus_aureus/alleles/SACOL2694.fasta

$(ASSETS_DIR)/cgmlst/staphylococcus_aureus/alleles/SACOL2694.fasta: $(ASSETS_DIR)/cgmlst/staphylococcus_aureus/alleles/cgmlst_141106.zip
	$(call log_message,"Unpacking S. Aureus cgMLST schema ...")
	cd $$(dirname $<) \
		&& unzip -Duq $$(basename $<)


saureus_prep_cgmlst_schema: $(ASSETS_DIR)/cgmlst/staphylococcus_aureus/alleles_rereffed/Staphylococcus_aureus.trn

$(ASSETS_DIR)/cgmlst/staphylococcus_aureus/alleles_rereffed/Staphylococcus_aureus.trn: $(ASSETS_DIR)/cgmlst/staphylococcus_aureus/alleles/SACOL2694.fasta
	$(call log_message,"Prepping S. Aureus cgMLST schema ...")
	cd $(ASSETS_DIR)/cgmlst/staphylococcus_aureus/ \
	&& echo "WARNING! Prepping cgMLST schema. This takes a looong time. Put on some coffee" \
	&& singularity exec --bind $(MNT_ROOT) $(CONTAINER_DIR)/chewbbaca.sif \
		chewie PrepExternalSchema \
		-i $(ASSETS_DIR)/cgmlst/staphylococcus_aureus/alleles \
		-o $(ASSETS_DIR)/cgmlst/staphylococcus_aureus/alleles_rereffed \
		--cpu 1 \
		--ptf $(ASSETS_DIR)/prodigal_training_files/Staphylococcus_aureus.trn

# -----------------------------
# E. coli
# -----------------------------

.PHONY: ecoli_all \
	ecoli_download_reference \
	ecoli_index_reference \
	ecoli_download_wgmlst_schema \
	ecoli_download_cgmlst_schema \
	ecoli_prep_ecoli_cgmlst_schema

ecoli_all: ecoli_index_reference \
	ecoli_download_wgmlst_schema \
	ecoli_prep_ecoli_cgmlst_schema


ecoli_download_reference: $(ASSETS_DIR)/genomes/escherichia_coli/NC_000913.3.fasta

$(ASSETS_DIR)/genomes/escherichia_coli/NC_000913.3.fasta:
	cd $(ASSETS_DIR)/.. \
	&& mkdir -p $(ASSETS_DIR)/genomes/escherichia_coli \
	&& singularity exec --bind $(MNT_ROOT) $(CONTAINER_DIR)/pythonScripts.sif \
		python3 bin/download_ncbi.py \
		-i NC_000913.3 \
		-o $(ASSETS_DIR)/genomes/escherichia_coli


ecoli_index_reference: $(ASSETS_DIR)/genomes/escherichia_coli/NC_000913.3.fasta.bwt

$(ASSETS_DIR)/genomes/escherichia_coli/NC_000913.3.fasta.bwt: $(ASSETS_DIR)/genomes/escherichia_coli/NC_000913.3.fasta
	cd $(ASSETS_DIR)/genomes/escherichia_coli \
	&& singularity exec --bind $(MNT_ROOT) $(CONTAINER_DIR)/bwakit.sif \
		bwa index NC_000913.3.fasta


# Download Ecoli wgmlst INNUENDO schema
ecoli_download_wgmlst_schema: $(ASSETS_DIR)/wgmlst/escherichia_coli/alleles/ecoli_INNUENDO_wgMLST/Escherichia_coli.trn

$(ASSETS_DIR)/wgmlst/escherichia_coli/alleles/ecoli_INNUENDO_wgMLST/Escherichia_coli.trn:
	mkdir -p $(ASSETS_DIR)/wgmlst/escherichia_coli/alleles &> /dev/null \
	&& cd $(ASSETS_DIR)/wgmlst/escherichia_coli/alleles \
	&& singularity exec --bind $(MNT_ROOT) $(CONTAINER_DIR)/chewbbaca.sif \
		chewie DownloadSchema \
		-sp 5 \
		-sc 1 \
		-o $(ASSETS_DIR)/wgmlst/escherichia_coli/alleles \
		--latest


# Download Ecoli cgmlst cgmlst.org schema
ecoli_download_cgmlst_schema: $(ASSETS_DIR)/cgmlst/escherichia_coli/alleles/ecoli_cgmlst_alleles_5064703.zip

$(ASSETS_DIR)/cgmlst/escherichia_coli/alleles/ecoli_cgmlst_alleles_5064703.zip:
	mkdir -p $(ASSETS_DIR)/cgmlst/escherichia_coli/alleles &> /dev/null \
	&& cd $(ASSETS_DIR)/cgmlst/escherichia_coli/alleles \
	&& wget -O ecoli_cgmlst_alleles_5064703.zip https://www.cgmlst.org/ncs/schema/5064703/alleles/ --no-check-certificate &> /dev/null


ecoli_unpack_cgmlst_schema: $(ASSETS_DIR)/cgmlst/escherichia_coli/alleles/b4383.fasta

$(ASSETS_DIR)/cgmlst/escherichia_coli/alleles/b4383.fasta: $(ASSETS_DIR)/cgmlst/escherichia_coli/alleles/ecoli_cgmlst_alleles_5064703.zip
	cd $(ASSETS_DIR)/cgmlst/escherichia_coli/alleles \
	&& unzip -Duq $$(basename $<)


## Prepping Ecoli cgmlst cgmlst.org schema
ecoli_prep_ecoli_cgmlst_schema: $(ASSETS_DIR)/cgmlst/escherichia_coli/alleles_rereffed/Escherichia_coli.trn

$(ASSETS_DIR)/cgmlst/escherichia_coli/alleles_rereffed/Escherichia_coli.trn: $(ASSETS_DIR)/cgmlst/escherichia_coli/alleles/b4383.fasta
	cd $(ASSETS_DIR)/cgmlst/escherichia_coli/ \
	&& echo "WARNING! Prepping cgMLST schema. This takes a looong time. Put on some coffee" \
	&& singularity exec --bind $(MNT_ROOT) $(CONTAINER_DIR)/chewbbaca.sif \
		chewie PrepExternalSchema \
		-i $(ASSETS_DIR)/cgmlst/escherichia_coli/alleles \
		-o $(ASSETS_DIR)/cgmlst/escherichia_coli/alleles_rereffed \
		--cpu 1 \
		--ptf $(ASSETS_DIR)/prodigal_training_files/Escherichia_coli.trn


# -----------------------------
# K. pneumoniae
# -----------------------------
#  [>] TODO: Test-run

.PHONY: kpneumoniae_all \
	kpneumoniae_download_reference \
	kpneumoniae_index_reference \
	kpneumoniae_download_cgmlst_schema \
	kpneumoniae_prep_cgmlst_schema

kpneumoniae_all: kpneumoniae_download_reference \
	kpneumoniae_index_reference \
	kpneumoniae_download_cgmlst_schema \
	kpneumoniae_prep_cgmlst_schema


kpneumoniae_download_reference: $(ASSETS_DIR)/genomes/klebsiella_pneumoniae/NC_016845.1.fasta

$(ASSETS_DIR)/genomes/klebsiella_pneumoniae/NC_016845.1.fasta:
	cd $(ASSETS_DIR)/.. \
	&& mkdir -p $(ASSETS_DIR)/genomes/klebsiella_pneumoniae \
	&& singularity exec --bind $(MNT_ROOT) $(CONTAINER_DIR)/pythonScripts.sif \
		python3 bin/download_ncbi.py \
		-i NC_016845.1 \
		-o $(ASSETS_DIR)/genomes/klebsiella_pneumoniae


kpneumoniae_index_reference: $(ASSETS_DIR)/genomes/klebsiella_pneumoniae/NC_016845.1.fasta.bwt

$(ASSETS_DIR)/genomes/klebsiella_pneumoniae/NC_016845.1.fasta.bwt:
	cd $(ASSETS_DIR)/genomes/klebsiella_pneumoniae \
	&& singularity exec --bind $(MNT_ROOT) $(CONTAINER_DIR)/bwakit.sif \
		bwa index NC_016845.1.fasta


# Download Kpneumoniae cgmlst cgmlst.org schema
kpneumoniae_download_cgmlst_schema:
	mkdir -p $(ASSETS_DIR)/cgmlst/klebsiella_pneumoniae/alleles &> /dev/null \
	&& cd $(ASSETS_DIR)/cgmlst/klebsiella_pneumoniae/alleles \
	&& wget https://www.cgmlst.org/ncs/schema/2187931/alleles/ --no-check-certificate &> /dev/null \
	&& unzip index.html &> /dev/null

# Prep Kpneumoniae cgmlst cgmlst.org schema
kpneumoniae_prep_cgmlst_schema:
	cd $(ASSETS_DIR)/cgmlst/klebsiella_pneumoniae/ \
	&& echo "WARNING! Prepping cgMLST schema. This takes a looong time. Put on some coffee" \
	&& singularity exec --bind $(MNT_ROOT) $(CONTAINER_DIR)/chewbbaca.sif \
		chewie PrepExternalSchema \
		-i $(ASSETS_DIR)/cgmlst/klebsiella_pneumoniae/alleles \
		-o $(ASSETS_DIR)/cgmlst/klebsiella_pneumoniae/alleles_rereffed \
		--cpu 1 \
		--ptf $(ASSETS_DIR)/prodigal_training_files/Klebsiella_pneumoniae.trn #TO-DO: create Kpneumoniae training file

# -----------------------------
# M. tuberculosis
# -----------------------------
.PHONY: mtuberculosis_all mtuberculosis_download_reference mtuberculosis_index_reference

mtuberculosis_all: mtuberculosis_download_reference mtuberculosis_index_reference

mtuberculosis_download_reference:
	cd $(ASSETS_DIR)/.. \
	&& singularity exec --bind $(MNT_ROOT) $(CONTAINER_DIR)/pythonScripts.sif \
		python3 bin/download_ncbi.py \
		-i NC_000962.3 \
		-o $(ASSETS_DIR)/genomes/mycobacterium_tuberculosis

mtuberculosis_index_reference:
	cd $(ASSETS_DIR)/genomes/mycobacterium_tuberculosis
	singularity exec --bind $(MNT_ROOT) $(CONTAINER_DIR)/bwakit.sif \
		bwa index NC_016845.1.fasta

# ==============================================================================
# Perform checks
# ==============================================================================
# TODO: Integrate with main installation rules?

# -----------------------------
# Check chewBBACA
# -----------------------------
check_chewbbaca:
	@cd $(ASSETS_DIR)/.. \
	&& saureus=$(ASSETS_DIR)/cgmlst/staphylococcus_aureus/alleles_rereffed \
	&& if [ -d "$$saureus" ]; then \
		echo "$$saureus exists."; \
	else \
		echo "ERROR: $$saureus does not exist!!! Please report this to JASEN issues."; \
	fi

# -----------------------------
# Check BWA
# -----------------------------
check_bwa:
	@cd $(ASSETS_DIR)/.. \
	&& ref=$(ASSETS_DIR)/genomes/staphylococcus_aureus/NC_002951.2.fasta; \
		refamb=$${ref}.amb; \
		refann=$${ref}.ann; \
		refbwt=$${ref}.bwt; \
		refpac=$${ref}.pac; \
		refsa=$${ref}.sa \
	&& if [[ -f $$ref \
		&& -f $${refamb} \
		&& -f $${refann} \
		&& -f $${refbwt} \
		&& -f $${refpac} \
		&& -f $${refsa} \
	]]; then \
		echo "bwa indexes exists."; \
	else \
		echo "ERROR: bwa indexes do not exist!!! Please report this to JASEN issues."; \
	fi

# -----------------------------
# Check BlastDB
# -----------------------------
check_blastdb:
	@cd $(ASSETS_DIR)/.. \
	&& mlst=$(ASSETS_DIR)/mlst_db/blast/mlst.fa; \
	 mlstndb=$${mlst}.ndb; \
	 mlstnhd=$${mlst}.nhd; \
	 mlstnhi=$${mlst}.nhi; \
	 mlstnhr=$${mlst}.nhr; \
	 mlstnin=$${mlst}.nin; \
	 mlstnog=$${mlst}.nog; \
	 mlstnos=$${mlst}.nos; \
	 mlstnot=$${mlst}.not; \
	 mlstnsq=$${mlst}.nsq; \
	 mlstntf=$${mlst}.ntf; \
	 mlstnto=$${mlst}.nto \
	&& if [[ -f $${mlst} \
		&& -f $${mlstndb} \
		&& -f $${mlstnhd} \
		&& -f $${mlstnhi} \
		&& -f $${mlstnhr} \
		&& -f $${mlstnin} \
		&& -f $${mlstnog} \
		&& -f $${mlstnos} \
		&& -f $${mlstnot} \
		&& -f $${mlstnsq} \
		&& -f $${mlstntf} \
		&& -f $${mlstnto} \
	]]; then \
		echo "BLAST indexes exists!"; \
	else \
		echo "ERROR: BLAST indexes do not exist!!! Please report this to JASEN issues."; \
	fi
