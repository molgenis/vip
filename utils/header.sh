#!/bin/bash
set -euo pipefail

MOD_BCF_TOOLS="BCFtools/1.10.2-GCCcore-7.3.0"
MOD_CADD="CADD/v1.4-foss-2018b-minimal"
MOD_CAPICE="CAPICE/v1.3.0-foss-2018b"
MOD_HTS_LIB="HTSlib/1.10.2-GCCcore-7.3.0"
MOD_VCF_ANNO="vcfanno/v0.3.2"
MOD_VCF_DECISION_TREE="vcf-decision-tree/v0.0.2-Java-11-LTS"
MOD_VCF_INHERITANCE_MATCHER="vcf-inheritance-matcher/v0.0.3-Java-11-LTS"
MOD_VCF_REPORT="vcf-report/v1.4.0-Java-11-LTS"
MOD_VEP="VEP/100.4-foss-2018b-Perl-5.28.0"
MOD_PYTHON_PLUS="PythonPlus/3.7.4-foss-2018b-v20.11.1"

# Use non-minimal CADD module if the minimal module is not available
if ! module is-avail "${MOD_CADD}"; then
  MOD_CADD="${MOD_CADD%-minimal}"
fi

# Exits if (the specific version of) a module is missing.
for i in ${!MOD_*}; do if ! module is-avail ${!i}; then echo "missing module: ${!i}"; exit 1; fi; done
