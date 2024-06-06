#!/bin/bash
set -euo pipefail

create_ped () {
  echo -e "!{pedigreeContent}" > "!{pedigree}"
}

inheritance () {
  local args=()
  args+=("-Djava.io.tmpdir=\"${TMPDIR}\"")
  args+=("-XX:ParallelGCThreads=2")
  args+=("-Xmx!{task.memory.toMega() - 512}m")
  args+=("-jar" "/opt/vcf-inheritance-matcher/lib/vcf-inheritance-matcher.jar")
  args+=("--input" "!{vcf}")
  args+=("--output" "!{vcfOut}")
  if [ -n "!{pedigree}" ]; then
    args+=("--pedigree" "!{pedigree}")
  fi
  if [ -n "!{probands}" ]; then
    args+=("--probands" "!{probands}")
  fi

  ${CMD_VCFINHERITANCEMATCHER} java "${args[@]}"
}

index () {
  ${CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcfOut}"
  ${CMD_BCFTOOLS} index --stats "!{vcfOut}" > "!{vcfOutStats}"
}

#Workaround for https://github.com/samtools/htsjdk/issues/500https://github.com/samtools/htsjdk/issues/500
store_alt(){
  #store ALT headers
  zcat "!{vcf}" | sed --quiet --expression='/^##ALT/p' > header.tmp
}

insert_alt(){
  if [ -s header.tmp ]; then
    #remove remaining ALT header (since htsjdk stores in a map, a single ALT remains)
    zcat "!{vcfOut}" | sed '/^##ALT/d' > "!{vcfOut}".tmp
    #re-insert the ALT headers
    f1=$(<header.tmp)
    awk -vf1="$f1" '/^#CHROM/{print f1;print;next}1' "!{vcfOut}".tmp | ${CMD_BGZIP} -c > "!{vcfOut}"
    #rm header.tmp
  fi
}

main() {
  create_ped
  store_alt
  inheritance
  insert_alt
  index
}

main "$@"