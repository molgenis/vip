#!/bin/bash
set -euo pipefail

mosdepth () {
    # Spectre recommends running Mosdepth with a bin size of 1kb and a mapping quality of at least 20
    local args=()
    args+=("--threads"  "!{task.cpus}")
    args+=("--by" "1000")
    args+=("--fasta" "!{paramReference}")
    args+=("--mapq" "20")
    args+=("--fast-mode")
    args+=("mosdepth")
    args+=("!{cram}")
    ${CMD_MOSDEPTH} "${args[@]}"
}

call_copy_number_variation () {
    local args=()
    args+=("CNVCaller")
    args+=("--coverage" "mosdepth.regions.bed.gz")
    args+=("--sample-id" "!{sampleId}")
    args+=("--output-dir" "spectre")
    args+=("--reference" "!{paramReference}")
    args+=("--metadata" "!{paramMetadata}")
    args+=("--blacklist" "!{paramBlacklist}")
    args+=("--threads" "!{task.cpus}")
    if [ "!{sampleSex}" == "male" ]; then
        args+=("--ploidy-chr" "chrX:1,chrY:1")
    else
        args+=("--ploidy-chr" "chrX:2")
    fi

    ${CMD_SPECTRE} "${args[@]}"
}

fixref () {
  # Workaround for TODO
  zcat "./spectre/!{sampleId}.vcf.gz" | \
  while IFS=$'\t' read -r -a fields
  do
    if [[ "${fields[0]}" != \#* && "${fields[3]}" == "N" ]]; then
      ref=$(${CMD_SAMTOOLS} faidx "!{paramReference}" "${fields[0]}:${fields[1]}-${fields[1]}" | sed -n '2 p')
      fields[3]="${ref}"
      length="${#fields[4]}"
      #Fix breakend ALTS
      if [[ "${fields[4]}" == \]* && "${fields[4]}" == *N ]]; then
        fields[4]="${fields[4]:0:(length-1)}${ref}"
      elif [[ "${fields[4]}" == *\[ && "${fields[4]}" == N* ]]; then
        fields[4]="${ref}${fields[4]:1:length}"
      #Fix regular insertion ALT
      elif [[ "${fields[4]}" == N* && "${length}" -gt 1 ]]; then
        fields[4]="${ref}${fields[4]:1:length}"
      fi
    fi
    (IFS=$'\t'; echo "${fields[*]}") >> "fixed_ref_output.vcf"
  done
  ${CMD_BCFTOOLS} view --output-type z --output "!{vcfOut}" --no-version --threads "!{task.cpus}" fixed_ref_output.vcf
  rm "fixed_ref_output.vcf"
}

index () {
    ${CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcfOut}"
    ${CMD_BCFTOOLS} index --stats "!{vcfOut}" > "!{vcfOutStats}"
}

main() {
    mosdepth
    call_copy_number_variation
    fixref
    index
}

main "$@"
