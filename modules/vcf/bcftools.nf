// TODO code deduplication with bcftools_concat
process bcftools_concat_index {
  publishDir "$params.output", mode: 'link'

  input:
    tuple val(meta), path(gVcfs)
  output:
    tuple path(gVcf), path(gVcfCsi)
  shell:
    gVcf="${meta.individual_id}.g.vcf.gz"
    gVcfCsi="${meta.individual_id}.g.vcf.gz.csi"
    
    template 'bcftools_concat_index.sh'
}

process bcftools_view_contig {
  input:
    tuple val(meta), path(gVcf), path(gVcfIndex)
  output:
    tuple val(meta), path(gVcfContig)
  shell:
    gVcfContig="${meta.sample.individual_id}_${meta.contig}.g.vcf.gz"
    
    template 'bcftools_view_contig.sh'
}

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

process bcftools_index_count {
  input:
    tuple val(meta), path(vcfIndex)
  output:
    count
  shell:
    template 'bcftools_index_count.sh'
}

process bcftools_index {
  input:
    tuple val(meta), path(vcf)
  output:
    tuple val(meta), path(vcfIndex)
  shell:
    vcfIndex="${vcf}.csi"

    template 'bcftools_index.sh'
}