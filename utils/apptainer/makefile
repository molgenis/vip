DEF_DIR := def
DEF_BUILD_DIR := $(DEF_DIR)/build
SIF_DIR := sif
SIF_BUILD_DIR := $(SIF_DIR)/build

VER_ALPINE := 3.23.3
VER_ANNOTSV := 3.4.6
VER_BCFTOOLS := 1.20
VER_CAPICE := 5.1.2
VER_CUTESV := 2.1.3-patch1
VER_DEBIAN := 13.3
VER_EXPANSIONHUNTER := 5.0.0_v2
VER_FASTP := 0.23.4_v2
VER_GADO := 1.0.3_v2
VER_MANTA := 1.6.0
VER_MINIMAP2 := 2.27_v2
VER_OPENJDK := 25
VER_PICARD := 3.1.1_v2
VER_PYTHON := 3.11.14
VER_SAMTOOLS := 1.17-patch1
VER_SEQTK := 1.4_v2
VER_SPECTRE := 0.2.1-patched_v2
VER_STRAGLR := 1.5.6
VER_STRAGLR_TSV2VCF := 1.2.0
VER_STRANGER := 0.9.3
VER_VCF_DECISION_TREE := 6.0.0
VER_VCF_INHERITANCE_MATCHER := 4.0.0
VER_VCF_REPORT := 8.2.0
VER_WHATSHAP := 2.4

SIF_ALPINE := $(SIF_BUILD_DIR)/alpine-$(VER_ALPINE).sif
SIF_ANNOTSV := $(SIF_DIR)/annotsv-$(VER_ANNOTSV).sif
SIF_BCFTOOLS := $(SIF_DIR)/bcftools-$(VER_BCFTOOLS).sif
SIF_CAPICE := $(SIF_DIR)/capice-$(VER_CAPICE).sif
SIF_CUTESV := $(SIF_DIR)/cutesv-$(VER_CUTESV).sif
SIF_DEBIAN := $(SIF_BUILD_DIR)/debian-$(VER_DEBIAN).sif
SIF_EXPANSIONHUNTER := $(SIF_DIR)/expansionhunter-$(VER_EXPANSIONHUNTER).sif
SIF_FASTP := $(SIF_DIR)/fastp-$(VER_FASTP).sif
SIF_GADO := $(SIF_DIR)/gado-$(VER_GADO).sif
SIF_MANTA := $(SIF_DIR)/manta-$(VER_MANTA).sif
SIF_MINIMAP2 := $(SIF_DIR)/minimap2-$(VER_MINIMAP2).sif
SIF_OPENJDK := $(SIF_BUILD_DIR)/openjdk-$(VER_OPENJDK).sif
SIF_PICARD := $(SIF_DIR)/picard-$(VER_PICARD).sif
SIF_PYTHON := $(SIF_BUILD_DIR)/python-$(VER_PYTHON).sif
SIF_SAMTOOLS := $(SIF_DIR)/samtools-$(VER_SAMTOOLS).sif
SIF_SEQTK := $(SIF_DIR)/seqtk-$(VER_SEQTK).sif
SIF_SPECTRE := $(SIF_DIR)/spectre-$(VER_SPECTRE).sif
SIF_STRAGLR := $(SIF_DIR)/straglr-$(VER_STRAGLR).sif
SIF_STRAGLR_TSV2VCF := $(SIF_DIR)/straglr-tsv2vcf-$(VER_STRAGLR_TSV2VCF).def
SIF_STRANGER := $(SIF_DIR)/stranger-$(VER_STRANGER).sif
SIF_VCF_DECISION_TREE := $(SIF_DIR)/vcf-decision-tree-$(VER_VCF_DECISION_TREE).sif
SIF_VCF_INHERITANCE_MATCHER := $(SIF_DIR)/vcf-inheritance-matcher-$(VER_VCF_INHERITANCE_MATCHER).sif
SIF_VCF_REPORT := $(SIF_DIR)/vcf-report-$(VER_VCF_REPORT).sif
SIF_WHATSHAP := $(SIF_DIR)/whatshap-$(VER_WHATSHAP).sif

BUILD_CMD := sudo apptainer --quiet build \
    --disable-cache \
    --force \
    --mksquashfs-args "-quiet -reproducible -no-xattrs -comp zstd -Xcompression-level 19"

# default target
.PHONY: all
all: \
	alpine \
	annotsv \
	bcftools \
	capice \
	cutesv \
	debian \
	expansionhunter \
	fastp \
	gado \
	manta \
	minimap2 \
	openjdk \
	picard \
	python \
	samtools \
	seqtk \
	spectre \
	straglr \
	straglr_tsv2vcf \
	stranger \
	vcf-decision-tree \
	vcf-inheritance-matcher \
	vcf-report \
	whatshap

# clean
.PHONY: clean
clean:
	rm -rf $(SIF_DIR) $(SIF_BUILD_DIR)
.NOTPARALLEL: clean

# directories
$(SIF_BUILD_DIR):
	mkdir -p $@

$(SIF_DIR):
	mkdir -p $@

# alpine
$(SIF_ALPINE): $(DEF_BUILD_DIR)/alpine-$(VER_ALPINE).def \
	| $(SIF_BUILD_DIR)
	$(BUILD_CMD) $@ $<
.PHONY: alpine
alpine: $(SIF_ALPINE)

# annotsv: depends on bcftools, openjdk
$(SIF_ANNOTSV): $(DEF_DIR)/annotsv-$(VER_ANNOTSV).def \
	$(SIF_BCFTOOLS) \
	$(SIF_OPENJDK) \
	| $(SIF_DIR)
	$(BUILD_CMD) $@ $<
.PHONY: annotsv
annotsv: $(SIF_ANNOTSV)

# bcftools: depends on alpine
$(SIF_BCFTOOLS): $(DEF_DIR)/bcftools-$(VER_BCFTOOLS).def \
	$(SIF_ALPINE) \
	| $(SIF_DIR)
	$(BUILD_CMD) $@ $<
.PHONY: bcftools
bcftools: $(SIF_BCFTOOLS)

# capice: depends on python
$(SIF_CAPICE): $(DEF_DIR)/capice-$(VER_CAPICE).def \
	$(SIF_PYTHON) \
	| $(SIF_DIR)
	$(BUILD_CMD) $@ $<
.PHONY: capice
capice: $(SIF_CAPICE)

# cutesv: depends on python
$(SIF_CUTESV): $(DEF_DIR)/cutesv-$(VER_CUTESV).def \
	$(SIF_PYTHON) \
	| $(SIF_DIR)
	$(BUILD_CMD) $@ $<
.PHONY: cutesv
cutesv: $(SIF_CUTESV)

# debian
$(SIF_DEBIAN): $(DEF_BUILD_DIR)/debian-$(VER_DEBIAN).def \
	| $(SIF_BUILD_DIR)
	$(BUILD_CMD) $@ $<
.PHONY: debian
debian: $(SIF_DEBIAN)

# expansionhunter: depends on alpine
$(SIF_EXPANSIONHUNTER): $(DEF_DIR)/expansionhunter-$(VER_EXPANSIONHUNTER).def \
	$(SIF_ALPINE) \
	| $(SIF_DIR)
	$(BUILD_CMD) $@ $<
.PHONY: expansionhunter
expansionhunter: $(SIF_EXPANSIONHUNTER)

# fastp: depends on alpine
$(SIF_FASTP): $(DEF_DIR)/fastp-$(VER_FASTP).def \
	$(SIF_ALPINE) \
	| $(SIF_DIR)
	$(BUILD_CMD) $@ $<
.PHONY: fastp
fastp: $(SIF_FASTP)

# gado: depends on openjdk
$(SIF_GADO): $(DEF_DIR)/gado-$(VER_GADO).def \
	$(SIF_OPENJDK) \
	| $(SIF_DIR)
	$(BUILD_CMD) $@ $<
.PHONY: gado
gado: $(SIF_GADO)

# manta: depends on debian
$(SIF_MANTA): $(DEF_DIR)/manta-$(VER_MANTA).def \
	$(SIF_DEBIAN) \
	| $(SIF_DIR)
	$(BUILD_CMD) $@ $<
.PHONY: manta
manta: $(SIF_MANTA)

# minimap2: depends on alpine
$(SIF_MINIMAP2): $(DEF_DIR)/minimap2-$(VER_MINIMAP2).def \
	$(SIF_ALPINE) \
	| $(SIF_DIR)
	$(BUILD_CMD) $@ $<
.PHONY: minimap2
minimap2: $(SIF_MINIMAP2)

# openjdk: depends on alpine
$(SIF_OPENJDK): $(DEF_BUILD_DIR)/openjdk-$(VER_OPENJDK).def \
	$(SIF_ALPINE) \
	| $(SIF_BUILD_DIR)
	$(BUILD_CMD) $@ $<
.PHONY: openjdk
openjdk: $(SIF_OPENJDK)

# picard: depends on openjdk
$(SIF_PICARD): \
	$(DEF_DIR)/picard-$(VER_PICARD).def \
	$(SIF_OPENJDK) \
	| $(SIF_DIR)
	$(BUILD_CMD) $@ $<
.PHONY: picard
picard: $(SIF_PICARD)

# python
$(SIF_PYTHON): $(DEF_BUILD_DIR)/python-$(VER_PYTHON).def \
	$(SIF_BUILD_DIR)
	$(BUILD_CMD) $@ $<
.PHONY: python
python: $(SIF_PYTHON)

# samtools: depends on debian
$(SIF_SAMTOOLS): $(DEF_DIR)/samtools-$(VER_SAMTOOLS).def \
	$(SIF_DEBIAN) \
	| $(SIF_DIR)
	$(BUILD_CMD) $@ $<
.PHONY: samtools
samtools: $(SIF_SAMTOOLS)

# seqtk: depends on alpine
$(SIF_SEQTK): $(DEF_DIR)/seqtk-$(VER_SEQTK).def \
	$(SIF_ALPINE) \
	| $(SIF_DIR)
	$(BUILD_CMD) $@ $<
.PHONY: seqtk
seqtk: $(SIF_SEQTK)

# spectre: depends on alpine
$(SIF_SPECTRE): $(DEF_DIR)/spectre-$(VER_SPECTRE).def \
	$(SIF_ALPINE) \
	| $(SIF_DIR)
	$(BUILD_CMD) $@ $<
.PHONY: spectre
spectre: $(SIF_SPECTRE)

# straglr: depends on debian
$(SIF_STRAGLR): $(DEF_DIR)/straglr-$(VER_STRAGLR).def \
	$(SIF_DEBIAN) \
	| $(SIF_DIR)
	$(BUILD_CMD) $@ $<
.PHONY: straglr
manta: $(SIF_STRAGLR)

# straglr_tsv2vcf: depends on openjdk
$(SIF_STRAGLR_TSV2VCF): \
	$(DEF_DIR)/straglr-tsv2vcf-$(VER_STRAGLR_TSV2VCF).def \
	$(SIF_OPENJDK) \
	| $(SIF_DIR)
	$(BUILD_CMD) $@ $<
.PHONY: straglr_tsv2vcf
straglr_tsv2vcf: $(SIF_STRAGLR_TSV2VCF)

# stranger: depends on alpine
$(SIF_STRANGER): $(DEF_DIR)/stranger-$(VER_STRANGER).def \
	$(SIF_ALPINE) \
	| $(SIF_DIR)
	$(BUILD_CMD) $@ $<
.PHONY: stranger
stranger: $(SIF_STRANGER)

# vcf-decision-tree: depends on openjdk
$(SIF_VCF_DECISION_TREE): \
	$(DEF_DIR)/vcf-decision-tree-$(VER_VCF_DECISION_TREE).def \
	$(SIF_OPENJDK) \
	| $(SIF_DIR)
	$(BUILD_CMD) $@ $<
.PHONY: vcf-decision-tree
vcf-decision-tree: $(SIF_VCF_DECISION_TREE)

# vcf-inheritance-matcher: depends on openjdk
$(SIF_VCF_INHERITANCE_MATCHER): \
	$(DEF_DIR)/vcf-inheritance-matcher-$(VER_VCF_INHERITANCE_MATCHER).def \
	$(SIF_OPENJDK) \
	| $(SIF_DIR)
	$(BUILD_CMD) $@ $<
.PHONY: vcf-inheritance-matcher
vcf-inheritance-matcher: $(SIF_VCF_INHERITANCE_MATCHER)

# vcf-report: depends on openjdk
$(SIF_VCF_REPORT): \
	$(DEF_DIR)/vcf-report-$(VER_VCF_REPORT).def \
	$(SIF_OPENJDK) \
	| $(SIF_DIR)
	$(BUILD_CMD) $@ $<
.PHONY: vcf-report
vcf-report: $(SIF_VCF_REPORT)

# whatshap: depends on python
$(SIF_WHATSHAP): $(DEF_DIR)/whatshap-$(VER_WHATSHAP).def \
	$(SIF_PYTHON) \
	| $(SIF_DIR)
	$(BUILD_CMD) $@ $<
.PHONY: whatshap
whatshap: $(SIF_WHATSHAP)

