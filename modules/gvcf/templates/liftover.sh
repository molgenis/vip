#!/bin/bash
set -euo pipefail

liftover() {
  local args=()
  args+=("-Djava.io.tmpdir=\"${TMPDIR}\"")
  args+=("-XX:ParallelGCThreads=2")
  args+=("-Xmx!{task.memory.toGiga()}g")
  args+=("-jar" "/opt/picard/lib/picard.jar")
  args+=("LiftoverVcf")
  args+=("--CHAIN" "!{chain}")
  args+=("--INPUT" "!{gVcf}")
  args+=("--OUTPUT" "picard_accepted.g.vcf.gz")
  args+=("--REFERENCE_SEQUENCE" "!{reference}")
  args+=("--REJECT" "picard_rejected.g.vcf.gz")
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
  ${CMD_BCFTOOLS} view --output-type z --output "!{gVcfOut}" --no-version --threads "!{task.cpus}" "picard_accepted.g.vcf.gz"
  ${CMD_BCFTOOLS} index --csi --output "!{gVcfOutIndex}" --threads "!{task.cpus}" "!{gVcfOut}"
  ${CMD_BCFTOOLS} index --stats "!{gVcfOut}" > "!{gVcfOutStats}"

  ${CMD_BCFTOOLS} view --output-type z --output "!{gVcfOutRejected}" --no-version --threads "!{task.cpus}" "picard_rejected.g.vcf.gz"
  ${CMD_BCFTOOLS} index --csi --output "!{gVcfOutRejectedIndex}" --threads "!{task.cpus}" "!{gVcfOutRejected}"
  ${CMD_BCFTOOLS} index --stats "!{gVcfOutRejected}" > "!{gVcfOutRejectedStats}"
}

cleanup(){
  rm picard_accepted.g.vcf.gz
  rm picard_rejected.g.vcf.gz
}

main() {
  liftover
  postprocess
  cleanup
}

main "$@"