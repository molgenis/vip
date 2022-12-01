process classify {
  input:
    tuple val(meta), path(vcfPath), path(vcfPathCsi)
  output:
    tuple val(meta), path(vcfClassifiedPath), path("${vcfClassifiedPath}.csi")
  shell:
    id = "${vcfPath.simpleName}"
    order = "${meta.chunk.index}"
    vcfClassifiedPath = "${id}_chunk${order}_classified.vcf.gz"
    template 'classify.sh'
}
