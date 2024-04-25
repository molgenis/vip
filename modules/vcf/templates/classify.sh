#!/bin/bash
set -euo pipefail

classify () {
  local args=()
  args+=("-Djava.io.tmpdir=\"${TMPDIR}\"")
  args+=("-XX:ParallelGCThreads=2")
  args+=("-Xmx!{task.memory.toMega() - 256}m")
  args+=("-jar" "/opt/vcf-decision-tree/lib/vcf-decision-tree.jar")
  args+=("--input" "!{vcf}")
  args+=("--metadata" "!{metadata}")
  args+=("--config" "decision_tree_updated.json")
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
    #rm header.tmp
  fi
}

write_tissue_file(){
  echo !{tissues} | tr ',' '\n' > tissues.tsv
}

update_tree(){
  tissuePath=$(realpath tissues.tsv)
  sed "s|TISSUE_FILE_PATH|${tissuePath}|g" "!{decisionTree}" > decision_tree_updated.json
}

main () {
  write_tissue_file
  update_tree
  store_alt
  classify
  insert_alt
  index
}

main "$@"