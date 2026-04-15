#!/bin/bash
set -euo pipefail

classify () {
  local args=()
  args+=("-Djava.io.tmpdir=\"${TMPDIR}\"")
  args+=("-XX:ParallelGCThreads=!{task.cpus - 1}")
  args+=("-Xmx!{(task.memory.toMega() * 0.75).intValue()}m")
  args+=("-jar" "/opt/vcf-decision-tree/lib/vcf-decision-tree.jar")
  args+=("--input" "!{vcf}_replaced.vcf.gz")
  args+=("--metadata" "!{metadata}")
  args+=("--config" "!{decisionTree}")
  if [ !{annotatePath} -eq 1 ]; then
    args+=("--path")
  fi

  args+=("--output" "!{vcfOut}_replaced.vcf.gz")

  ${CMD_VCFDECISIONTREE} java "${args[@]}"
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
  rm -f "!{vcf}_replaced.vcf.gz"
  rm -f "!{vcfOut}_replaced.vcf.gz"
  rm -f header.tmp
}

main () {
  trap 'rc=$?; cleanup; exit $rc' EXIT INT TERM

  store_alt
  replace_cnv_tr
  classify
  restore_cnv_tr
  insert_alt
  index
}

main "$@"
