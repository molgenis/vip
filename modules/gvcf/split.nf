process split {
  input:
    tuple val(meta), path(vcf), path(vcfIndex)
  output:
    tuple val(meta), path(vcfChunk), path("${vcfChunk}.csi")
  shell:
    basename = "${meta.sample.project_id}_chunk_${meta.chunk.index}"
    extension = "${vcf.name.substring(vcf.simpleName.length())}" // for example .vcf.gz or .g.vcf.gz
    vcfChunk="${basename}${extension}"

    bed="${basename}}.bed"
    bedContent = meta.chunk.regions.collect { region -> "${region.chrom}\t${region.chromStart}\t${region.chromEnd}" }.join("\n")

    template 'split.sh'
}