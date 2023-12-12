#!/bin/bash
set -euo pipefail

align() {
    local args_fastp=()
    args_fastp+=("--thread" "!{task.cpus}")
    if [[ "!{disable_quality_filtering}" == "true"  ]]; then
        args_fastp+=("--disable_quality_filtering")
    fi
    if [[ "!{disable_length_filtering}" == "true"  ]]; then
        args_fastp+=("--disable_length_filtering")
    fi
    if [[ "!{disable_adapter_trimming}" == "true"  ]]; then
        args_fastp+=("--disable_adapter_trimming")
    fi
    if [[ "!{disable_trim_poly_g}" == "true"  ]]; then
        args_fastp+=("--disable_trim_poly_g")
    fi
  if [[ -n "!{additional_params}" ]]; then
    for param in !{additional_params}
    do
       args_fastp+=("${param}")
    done
  fi
    args_fastp+=("--stdout")
    args_fastp+=("--html" "!{reportFile}")
    args_fastp+=("--in1" "!{fastqR1}")
    args_fastp+=("--in2" "!{fastqR2}")

    local args=()
    args+=("-t" "!{task.cpus}")
    args+=("-a")
    # MarkDuplicates uses the LB (= DNA preparation library identifier) field to determine which read groups might contain molecular duplicates, in case the same DNA library was sequenced on multiple lanes.
    args+=("-R" "@RG\tID:$(basename !{fastqR1})\tPL:!{platform}\tLB:!{sampleId}\tSM:!{sampleId}")
    args+=("-x" "sr")
    if [[ "!{softClipping}" == "true" ]]; then
        args+=("-Y")
    fi
    args+=("!{referenceMmi}")
    args+=("-")

    ${CMD_FASTP} "${args_fastp[@]}" | \
    ${CMD_MINIMAP2} "${args[@]}" | \
    ${CMD_SAMTOOLS} fixmate --no-PG -u -m -@ "!{task.cpus}" - - | \
    #position sort for markdup
    ${CMD_SAMTOOLS} sort --no-PG -u -@ "!{task.cpus}" --reference "!{reference}" -o "!{cram}" --write-index -
}

publish_fastp() {
  mkdir -p "!{outputPath}"
  cp "!{reportFile}" "!{outputPath}/!{reportFile}"
}

stats() {
  ${CMD_SAMTOOLS} idxstats "!{cram}" > "!{cramStats}"
}

main() {
  align
  publish_fastp
  stats
}

main "$@"
