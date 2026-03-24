filter_cram () {
    local filter_args=()
    filter_args+=("-T" "!{reference}")
    filter_args+=("-b")
    filter_args+=("-o" "!{cram}.chrm.bam")
    filter_args+=("-e" "rname == \"!{chrmName}\"")
    filter_args+=("!{cram}")

    ${CMD_SAMTOOLS} view "${filter_args[@]}"
    ${CMD_SAMTOOLS} index "!{cram}.chrm.bam"
}

mutect2 () {
    local mutect_args=()
    mutect_args+=("-Djava.io.tmpdir=${TMPDIR}")
    mutect_args+=("-XX:ParallelGCThreads=2")
    mutect_args+=("-Xmx!{task.memory.toMega() - 512}m")
    mutect_args+=("-jar" "/opt/gatk/lib/gatk.jar")
    mutect_args+=("Mutect2")
    mutect_args+=("-R" "!{reference}")
    mutect_args+=("-L" "!{chrmName}")
    mutect_args+=("--mitochondria-mode")
    mutect_args+=("-I" "!{cram}.chrm.bam")
    mutect_args+=("-O" "!{vcfOut}")
    mutect_args+=("--max-reads-per-alignment-start" "0")

    ${CMD_GATK} java "${mutect_args[@]}"
}

index () {
    ${CMD_BCFTOOLS} index --csi "!{vcfOut}"
    ${CMD_BCFTOOLS} stats "!{vcfOut}" > "!{vcfOutStats}"
}

cleanup () {
    rm "!{cram}.chrm.bam"
    rm "!{cram}.chrm.bam.bai"
}

main () {
    filter_cram
    mutect2
    index
    cleanup
}

main "$@"