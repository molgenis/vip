split_cram () {
    local split_args=()
    split_args+=("-T" "!{reference}")
    split_args+=("-C")
    split_args+=("-U" "!{nonchrmCramOut}")
    split_args+=("-o" "!{chrmCramOut}")
    split_args+=("-e" "rname == \"!{chrmName}\"")
    split_args+=("!{cram}")

    ${CMD_SAMTOOLS} view "${split_args[@]}"
}

index () {
    ${CMD_SAMTOOLS} index "!{chrmCramOut}"
    ${CMD_SAMTOOLS} index "!{nonchrmCramOut}"
}

main () {
    split_cram
    index
}

main "$@"