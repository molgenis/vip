# create/remove tmp directory (source: https://stackoverflow.com/a/77878760)
SHELL := /bin/bash
export TMPDIR:=$(shell mktemp --directory)
$(shell { trap 'rm -rf ${TMPDIR};' EXIT; tail --pid=$$PPID -f /dev/null; } </dev/null >/dev/null 2>/dev/null &)

# directories
DEF_DIR := def
DEF_BUILD_DIR := $(DEF_DIR)/build
DEF_UTILS_DIR := $(DEF_DIR)/utils
SIF_DIR := sif
SIF_BUILD_DIR := $(SIF_DIR)/build
SIF_UTILS_DIR := $(SIF_DIR)/utils

# .sif versions
VER_ALPINE := 3.23.3
VER_ANNOTSV := 3.4.6
VER_BCFTOOLS := 1.20
VER_CAPICE := 5.1.2
VER_CUTESV := 2.1.3-patch1
VER_DEBIAN := 13.3
VER_DEEPVARIANT := 1.9.0
VER_DEEPVARIANT_DEEPTRIO := 1.9.0
VER_EXPANSIONHUNTER := 5.0.0_v2
VER_FASTP := 0.23.4_v2
VER_GADO := 1.0.3_v2
VER_MANTA := 1.6.0
VER_MINIMAP2 := 2.27_v2
VER_MOSDEPTH := 0.3.8
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
VER_VCF_INHERITANCE := 3.2.1
VER_VCF_INHERITANCE_MATCHER := 4.0.0
VER_VCF_REPORT := 8.2.0
VER_VEP := 111.0
VER_WHATSHAP := 2.4

# .sif targets
SIF_ALPINE := $(SIF_BUILD_DIR)/alpine-$(VER_ALPINE).sif
SIF_ANNOTSV := $(SIF_DIR)/annotsv-$(VER_ANNOTSV).sif
SIF_BCFTOOLS := $(SIF_DIR)/bcftools-$(VER_BCFTOOLS).sif
SIF_CAPICE := $(SIF_DIR)/capice-$(VER_CAPICE).sif
SIF_CUTESV := $(SIF_DIR)/cutesv-$(VER_CUTESV).sif
SIF_DEBIAN := $(SIF_BUILD_DIR)/debian-$(VER_DEBIAN).sif
SIF_DEEPVARIANT := $(SIF_DIR)/deepvariant-$(VER_DEEPVARIANT).sif
SIF_DEEPVARIANT_DEEPTRIO := $(SIF_DIR)/deepvariant_deeptrio-$(VER_DEEPVARIANT_DEEPTRIO).sif
SIF_EXPANSIONHUNTER := $(SIF_DIR)/expansionhunter-$(VER_EXPANSIONHUNTER).sif
SIF_FASTP := $(SIF_DIR)/fastp-$(VER_FASTP).sif
SIF_GADO := $(SIF_DIR)/gado-$(VER_GADO).sif
SIF_MANTA := $(SIF_DIR)/manta-$(VER_MANTA).sif
SIF_MINIMAP2 := $(SIF_DIR)/minimap2-$(VER_MINIMAP2).sif
SIF_MOSDEPTH := $(SIF_DIR)/mosdepth-$(VER_MOSDEPTH).sif
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
SIF_VCF_INHERITANCE := $(SIF_UTILS_DIR)/vcf-inheritance-$(VER_VCF_INHERITANCE).sif
SIF_VCF_INHERITANCE_MATCHER := $(SIF_DIR)/vcf-inheritance-matcher-$(VER_VCF_INHERITANCE_MATCHER).sif
SIF_VCF_REPORT := $(SIF_DIR)/vcf-report-$(VER_VCF_REPORT).sif
SIF_VEP := $(SIF_DIR)/vep-$(VER_VEP).sif
SIF_WHATSHAP := $(SIF_DIR)/whatshap-$(VER_WHATSHAP).sif

# build settings
ARCH ?= amd64
ARCH_VARIANT ?= x86-64-v3

# build macro
# $1 = phony name
# $2 = .sif path
# $3 = .def path
# $4 = .sif dependencies (optional)
define build_image
$1: $2
.PHONY: $1
$2: $3 $4
	@mkdir -p $(dir $2)
	APPTAINER_TMPDIR=$(TMPDIR) apptainer --silent build \
		--arch $(ARCH) \
		--arch-variant $(ARCH_VARIANT) \
		--disable-cache \
		--fakeroot \
		--force \
		--mksquashfs-args "-quiet -reproducible -no-xattrs -comp zstd -Xcompression-level 19" \
		$$@ $$<;
endef

# target: default
.PHONY: all
all: \
        alpine \
        annotsv \
        bcftools \
        capice \
        cutesv \
        debian \
        deepvariant \
        deepvariant_deeptrio \
        expansionhunter \
        fastp \
        gado \
        manta \
        minimap2 \
        mosdepth \
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
        vcf-inheritance \
        vcf-inheritance-matcher \
        vcf-report \
        vep \
        whatshap

# target: clean
.PHONY: clean
clean:
	rm -rf $(SIF_DIR) $(SIF_BUILD_DIR) $(SIF_UTILS_DIR)
.NOTPARALLEL: clean

# target: build images
$(eval $(call build_image,alpine,$(SIF_ALPINE),$(DEF_BUILD_DIR)/alpine-$(VER_ALPINE).def,))
$(eval $(call build_image,annotsv,$(SIF_ANNOTSV),$(DEF_DIR)/annotsv-$(VER_ANNOTSV).def,$(SIF_BCFTOOLS) $(SIF_OPENJDK)))
$(eval $(call build_image,bcftools,$(SIF_BCFTOOLS),$(DEF_DIR)/bcftools-$(VER_BCFTOOLS).def,$(SIF_ALPINE)))
$(eval $(call build_image,capice,$(SIF_CAPICE),$(DEF_DIR)/capice-$(VER_CAPICE).def,$(SIF_PYTHON)))
$(eval $(call build_image,cutesv,$(SIF_CUTESV),$(DEF_DIR)/cutesv-$(VER_CUTESV).def,$(SIF_PYTHON)))
$(eval $(call build_image,debian,$(SIF_DEBIAN),$(DEF_BUILD_DIR)/debian-$(VER_DEBIAN).def,))
$(eval $(call build_image,deepvariant,$(SIF_DEEPVARIANT),$(DEF_DIR)/deepvariant-$(VER_DEEPVARIANT).def,))
$(eval $(call build_image,deepvariant_deeptrio,$(SIF_DEEPVARIANT_DEEPTRIO),$(DEF_DIR)/deepvariant_deeptrio-$(VER_DEEPVARIANT_DEEPTRIO).def,))
$(eval $(call build_image,expansionhunter,$(SIF_EXPANSIONHUNTER),$(DEF_DIR)/expansionhunter-$(VER_EXPANSIONHUNTER).def,$(SIF_ALPINE)))
$(eval $(call build_image,fastp,$(SIF_FASTP),$(DEF_DIR)/fastp-$(VER_FASTP).def,$(SIF_ALPINE)))
$(eval $(call build_image,gado,$(SIF_GADO),$(DEF_DIR)/gado-$(VER_GADO).def,$(SIF_OPENJDK)))
$(eval $(call build_image,manta,$(SIF_MANTA),$(DEF_DIR)/manta-$(VER_MANTA).def,$(SIF_DEBIAN)))
$(eval $(call build_image,minimap2,$(SIF_MINIMAP2),$(DEF_DIR)/minimap2-$(VER_MINIMAP2).def,$(SIF_ALPINE)))
$(eval $(call build_image,mosdepth,$(SIF_MOSDEPTH),$(DEF_DIR)/mosdepth-$(VER_MOSDEPTH).def,))
$(eval $(call build_image,openjdk,$(SIF_OPENJDK),$(DEF_BUILD_DIR)/openjdk-$(VER_OPENJDK).def,$(SIF_ALPINE)))
$(eval $(call build_image,picard,$(SIF_PICARD),$(DEF_DIR)/picard-$(VER_PICARD).def,$(SIF_OPENJDK)))
$(eval $(call build_image,python,$(SIF_PYTHON),$(DEF_BUILD_DIR)/python-$(VER_PYTHON).def,))
$(eval $(call build_image,samtools,$(SIF_SAMTOOLS),$(DEF_DIR)/samtools-$(VER_SAMTOOLS).def,$(SIF_DEBIAN)))
$(eval $(call build_image,seqtk,$(SIF_SEQTK),$(DEF_DIR)/seqtk-$(VER_SEQTK).def,$(SIF_ALPINE)))
$(eval $(call build_image,spectre,$(SIF_SPECTRE),$(DEF_DIR)/spectre-$(VER_SPECTRE).def,$(SIF_ALPINE)))
$(eval $(call build_image,straglr,$(SIF_STRAGLR),$(DEF_DIR)/straglr-$(VER_STRAGLR).def,$(SIF_DEBIAN)))
$(eval $(call build_image,straglr_tsv2vcf,$(SIF_STRAGLR_TSV2VCF),$(DEF_DIR)/straglr-tsv2vcf-$(VER_STRAGLR_TSV2VCF).def,$(SIF_OPENJDK)))
$(eval $(call build_image,stranger,$(SIF_STRANGER),$(DEF_DIR)/stranger-$(VER_STRANGER).def,$(SIF_ALPINE)))
$(eval $(call build_image,vcf-decision-tree,$(SIF_VCF_DECISION_TREE),$(DEF_DIR)/vcf-decision-tree-$(VER_VCF_DECISION_TREE).def,$(SIF_OPENJDK)))
$(eval $(call build_image,vcf-inheritance,$(SIF_VCF_INHERITANCE),$(DEF_UTILS_DIR)/vcf-inheritance-$(VER_VCF_INHERITANCE).def,$(SIF_OPENJDK)))
$(eval $(call build_image,vcf-inheritance-matcher,$(SIF_VCF_INHERITANCE_MATCHER),$(DEF_DIR)/vcf-inheritance-matcher-$(VER_VCF_INHERITANCE_MATCHER).def,$(SIF_OPENJDK)))
$(eval $(call build_image,vcf-report,$(SIF_VCF_REPORT),$(DEF_DIR)/vcf-report-$(VER_VCF_REPORT).def,$(SIF_OPENJDK)))
$(eval $(call build_image,vep,$(SIF_VEP),$(DEF_DIR)/vep-$(VER_VEP).def,))
$(eval $(call build_image,whatshap,$(SIF_WHATSHAP),$(DEF_DIR)/whatshap-$(VER_WHATSHAP).def,$(SIF_PYTHON)))
