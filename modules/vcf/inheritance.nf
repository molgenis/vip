process inheritance {
  input:
    tuple val(meta), path(vcfPath), path(vcfPathCsi)
  output:
    tuple val(meta), path(vcfInheritancePath), path("${vcfInheritancePath}.csi")
  shell:
    id = "${vcfPath.simpleName}"
    order = "${meta.chunk.index}"
    vcfInheritancePath = "${id}_chunk${order}_inheritance.vcf.gz"
    probands = meta.probands.collect{ proband -> [proband.family_id, proband.individual_id].join("_")}.join(",")
    template 'inheritance.sh'
}

process inheritance_publish {
  publishDir "$params.output", mode: 'copy'

  when: "$params.keep" == true

  input:
    tuple val(id), path(vcfPaths)
  output:
    tuple val(id), path(vcfMergedPath), path("${vcfMergedPath}.csi")
  shell:
    vcfMergedPath = "${id}_inheritance.vcf.gz"
    template 'merge.sh'
}
