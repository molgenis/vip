process split {
  input:
    tuple val(meta), path(vcf), path(vcfIndex)
  output:
    tuple val(meta), path(vcfChunk), path("${vcfChunk}.csi")
  shell:
    basename = "${meta.project_id}_chunk_${meta.chunk.index}"
    vcfChunk="${basename}.vcf.gz"

    bed="${basename}}.bed"
    bedContent = meta.chunk.regions.collect { region -> "${region.chrom}\t${region.chromStart}\t${region.chromEnd}" }.join("\n")
        
    template 'split.sh'
}