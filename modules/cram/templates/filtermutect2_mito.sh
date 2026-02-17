filtermutect2 () {
    local filtermutect_args=()
    filtermutect_args+=("-R" "!{reference}")
    filtermutect_args+=("-V" "!{vcf}")
    filtermutect_args+=("-O" "!{vcfOut}")
    filtermutect_args+=("--mitochondria-mode")

    ${CMD_GATK} FilterMutectCalls "${filtermutect_args[@]}"
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