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
  args+=("--input" "!{vcf}_replaced.vcf.gz")
  args+=("--output" "!{vcfOut}_replaced.vcf.gz")
  args+=("--metadata" "!{metadata}")
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

#Workaround for https://github.com/samtools/htsjdk/issues/500
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
  fi
}

#Workaround for https://github.com/samtools/htsjdk/issues/1718
replace_cnv_tr(){
  zcat "!{vcf}" | awk 'BEGIN{FS=OFS="\t"} {i=0; while(sub(/<CNV:TR>/,"<CNV:TR"++i">",$5));}1' | ${CMD_BGZIP} -c > "!{vcf}_replaced.vcf.gz"
}

restore_cnv_tr(){
  zcat "!{vcfOut}_replaced.vcf.gz" | awk 'BEGIN{FS=OFS="\t"} {gsub(/<CNV:TR[0-9]+>/,"<CNV:TR>",$5);}1' | ${CMD_BGZIP} -c > "!{vcfOut}"
}

cleanup(){
  rm "!{vcf}_replaced.vcf.gz"
  rm "!{vcfOut}_replaced.vcf.gz"
  rm header.tmp
}

main() {
  replace_cnv_tr
  create_ped
  store_alt
  inheritance
  restore_cnv_tr
  insert_alt
  index
  cleanup
}

main "$@"