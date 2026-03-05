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
    mutect_args+=("-I" "!{cram}")
    mutect_args+=("-O" "!{vcfOut}")
    mutect_args+=("--max-reads-per-alignment-start" "0")

    ${CMD_GATK} java "${mutect_args[@]}"
}

index () {
    ${CMD_BCFTOOLS} index --csi "!{vcfOut}"
    ${CMD_BCFTOOLS} stats "!{vcfOut}" > "!{vcfOutStats}"
}

main () {
    mutect2
    index
}

main "$@"