#!/bin/bash
set -euo pipefail

classify () {
  local args=()
  args+=("-Djava.io.tmpdir=\"${TMPDIR}\"")
  args+=("-XX:ParallelGCThreads=2")
  args+=("-Xmx!{task.memory.toMega() - 512}m")
  args+=("-jar" "/opt/vcf-decision-tree/lib/vcf-decision-tree.jar")
  args+=("--input" "!{vcf}")
  args+=("--metadata" "!{metadata}")
  args+=("--config" "!{decisionTree}")
  if [ !{annotatePath} -eq 1 ]; then
    args+=("--path")
  fi

  args+=("--output" "!{vcfOut}")

  ${CMD_VCFDECISIONTREE} java "${args[@]}"
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
  fi
}

replace_cnv_tr(){
  zcat !{vcf} | awk 'BEGIN{FS=OFS="\t"} {cnv_count = 1;while (gsub(/<CNV:TR>/, "<CNV:TR" cnv_count ">" $4) > 1 ) {cnv_count++;}print;}' | ${CMD_BGZIP} -c > !{vcf}_replaced.vcf.gz
}

restore_cnv_tr(){
  zcat !{vcfOut}_replaced.vcf.gz | awk 'BEGIN{FS=OFS="\t"} {gsub(/<CNV:TR[0-9]+>/, "<CNV:TR>", $4); print}' | ${CMD_BGZIP} -c > !{vcfOut}
}

cleanup(){
  rm !{vcf}_replaced.vcf.gz
  rm !{vcfOut}_replaced.vcf.gz
  rm header.tmp
}

main () {
  replace_cnv_tr
  store_alt
  classify
  restore_cnv_tr
  insert_alt
  index
  cleanup
}

main "$@"