process bcftools_view_chunk {
  input:
    tuple val(meta), path(gVcf), path(gVcfIndex)
  output:
    tuple val(meta), path(gVcfChunk), path(gVcfChunkIndex)
  shell:
    bed="chunk_${meta.chunk.index}.bed"
    bedContent = meta.chunk.regions.collect { region -> "${region.chrom}\t${region.chromStart}\t${region.chromEnd}" }.join("\n")
    gVcfChunk="${meta.sample.individual_id}_${meta.chunk.index}.g.vcf.gz"
    gVcfChunkIndex="${gVcfChunk}.csi"
    
    template 'bcftools_view_chunk.sh'
}
