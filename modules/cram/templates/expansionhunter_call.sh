#!/bin/bash
set -euo pipefail

call_short_tandem_repeats () {
    local args=()
    args+=("--reads" "!{cram}")
    args+=("--reference" "!{paramReference}")
    args+=("--variant-catalog" "!{paramVariantCatalog}")
    args+=("--output-prefix" "short_tandem_repeats")
    args+=("--region-extension-length" "!{paramRegionExtensionLength}")
    args+=("--sex" "!{sampleSex}")
    args+=("--log-level" "!{paramLogLevel}")
    args+=("--aligner" "!{paramAligner}")
    args+=("--analysis-mode" "!{paramAnalysisMode}")
    args+=("--threads" "!{task.cpus}")

    ${CMD_EXPANSIONHUNTER} "${args[@]}"
}

postprocess () {
  # workaround: ExpansionHunter extracts the sample name from the .cram, this might not be equals to the actual sample identifier
  # workaround: ExpansionHunter produces an invalid .vcf due to missing contig headers, see https://github.com/Illumina/ExpansionHunter/issues/153
  # workaround: ExpansionHunter produces an invalid .vcf due to missing headers if all calls are ./., see <TODO report issue>
  # workaround: ExpansionHunter are missing SVTYPE INFO field, see https://github.com/Illumina/ExpansionHunter/issues/186
  echo -e "!{sampleId}" > "samples.txt"
  ${CMD_BCFTOOLS} reheader --fai "!{paramReferenceFai}" --samples samples.txt --threads "!{task.cpus}" "short_tandem_repeats.vcf" | \
  ${CMD_BCFTOOLS} filter --exclude "GT=\"mis\"" --no-version --threads "!{task.cpus}"| \
  awk 'BEGIN{FS=OFS="\t"} /^#/ {print; next} {$8="SVTYPE=STR;"$8; print; next;} { print; }' | \
  ${CMD_BGZIP} -c > "!{vcfOut}"
}

index () {
  ${CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcfOut}"
  ${CMD_BCFTOOLS} index --stats "!{vcfOut}" > "!{vcfOutStats}"
}

main() {
    call_short_tandem_repeats
    postprocess
    index
}

main "$@"