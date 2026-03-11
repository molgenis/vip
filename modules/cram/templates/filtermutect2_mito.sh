filtermutect2 () {
    local filtermutect_args=()
    filtermutect_args+=("-Djava.io.tmpdir=${TMPDIR}")
    filtermutect_args+=("-XX:ParallelGCThreads=2")
    filtermutect_args+=("-Xmx!{task.memory.toMega() - 512}m")
    filtermutect_args+=("-jar” “/opt/gatk/lib/gatk.jar")
    filtermutect_args+=("FilterMutectCalls")
    filtermutect_args+=("-R" "!{reference}")
    filtermutect_args+=("-V" "!{vcf}")
    filtermutect_args+=("-O" "!{vcfOut}")
    filtermutect_args+=("--mitochondria-mode")

    ${CMD_GATK} java "${filtermutect_args[@]}"
}

index () {
    ${CMD_BCFTOOLS} index --csi "!{vcfOut}"
    ${CMD_BCFTOOLS} stats "!{vcfOut}" > "!{vcfOutStats}"
}

main () {
    filtermutect2
    index
}

main "$@"