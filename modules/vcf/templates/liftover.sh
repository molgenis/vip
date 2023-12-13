#!/bin/bash
set -euo pipefail

liftover() {
  local args=()
  args+=("-Djava.io.tmpdir=\"${TMPDIR}\"")
  args+=("-XX:ParallelGCThreads=2")
  args+=("-Xmx!{task.memory.toMega() - 256}m")
  args+=("-jar" "/opt/picard/lib/picard.jar")
  args+=("LiftoverVcf")
  args+=("--CHAIN" "!{chain}")
  args+=("--INPUT" "!{vcf}")
  args+=("--OUTPUT" "picard_accepted.vcf.gz")
  args+=("--REFERENCE_SEQUENCE" "!{reference}")
  args+=("--REJECT" "picard_rejected.vcf.gz")
  # as suggested by picard documentation
  args+=("--MAX_RECORDS_IN_RAM" "100000")
  args+=("--TMP_DIR" "$(realpath .)")
  args+=("--VERBOSITY" "WARNING")
  args+=("--WARN_ON_MISSING_CONTIG" "true")
  args+=("--WRITE_ORIGINAL_ALLELES" "true")
  args+=("--WRITE_ORIGINAL_POSITION" "true")

  ${CMD_PICARD} java "${args[@]}"
}

postprocess() {
  ${CMD_BCFTOOLS} view --output-type z --output "!{vcfOut}" --no-version --threads "!{task.cpus}" "picard_accepted.vcf.gz"
  ${CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcfOut}"
  ${CMD_BCFTOOLS} index --stats "!{vcfOut}" > "!{vcfOutStats}"

  ${CMD_BCFTOOLS} view --output-type z --output "!{vcfOutRejected}" --no-version --threads "!{task.cpus}" "picard_rejected.vcf.gz"
  ${CMD_BCFTOOLS} index --csi --output "!{vcfOutRejectedIndex}" --threads "!{task.cpus}" "!{vcfOutRejected}"
  ${CMD_BCFTOOLS} index --stats "!{vcfOutRejected}" > "!{vcfOutRejectedStats}"
}

cleanup(){
  rm picard_accepted.vcf.gz
  rm picard_rejected.vcf.gz
}

main() {
  liftover
  postprocess
  cleanup
}

main "$@"