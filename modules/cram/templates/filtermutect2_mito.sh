filtermutect2 () {
    local filtermutect_args=()
    filtermutect_args+=("-Djava.io.tmpdir=${TMPDIR}")
    filtermutect_args+=("-XX:ParallelGCThreads=2")
    filtermutect_args+=("-Xmx!{task.memory.toMega() - 512}m")
    filtermutect_args+=("-jar" "/opt/gatk/lib/gatk.jar")
    filtermutect_args+=("FilterMutectCalls")
    filtermutect_args+=("-R" "!{reference}")
    filtermutect_args+=("-V" "!{vcf}")
    filtermutect_args+=("-O" "!{tmpVcfName}.tmp.vcf.gz")
    filtermutect_args+=("--mitochondria-mode")
    filtermutect_args+=("--stats" "!{vcfStats}")
    filtermutect_args+=("--max-alt-allele-count" "4")

    ${CMD_GATK} java "${filtermutect_args[@]}"
}

index () {
    ${CMD_BCFTOOLS} index --csi "!{vcfOut}"
    ${CMD_BCFTOOLS} index --tbi "!{vcfOut}"
    ${CMD_BCFTOOLS} stats "!{vcfOut}" > "!{vcfOutStats}"
}

# Work around for issue described here: https://github.com/broadinstitute/gatk/issues/6857
fix_vcf () {
    gunzip -c "!{tmpVcfName}.tmp.vcf.gz" | sed 's|##INFO=<ID=AS_FilterStatus,Number=A,Type=String,Description="Filter status for each allele, as assessed by ApplyVQSR. Note that the VCF filter field will reflect the most lenient/sensitive status across all alleles.">|##INFO=<ID=AS_FilterStatus,Number=.,Type=String,Description="Filter status for each allele, as assessed by ApplyVQSR. Note that the VCF filter field will reflect the most lenient/sensitive status across all alleles.">|' > "!{tmpVcfName}.filtered.vcf"
    ${CMD_BGZIP} "!{tmpVcfName}.filtered.vcf"
}

tmp_index () {
    ${CMD_BCFTOOLS} index --csi "!{tmpVcfName}.tmp.vcf.gz"
}

cleanup () {
    mv "!{tmpVcfName}.tmp.vcf.gz.filteringStats.tsv" "!{vcfOut}.filteringStats.tsv"
    rm "!{tmpVcfName}.tmp.vcf.gz"
    rm "!{tmpVcfName}.tmp.vcf.gz.csi"
    rm "!{tmpVcfName}.tmp.vcf.gz.tbi"
}

main () {
    filtermutect2
    tmp_index
    fix_vcf
    index
    cleanup
}

main "$@"