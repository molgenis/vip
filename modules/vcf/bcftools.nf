// FIXME add meta input and determine output name from meta
process bcftools_concat {
  input:
    tuple val(meta), path(bcfs)
  output:
    tuple val(meta), path(vcf), path(vcfCsi)
  script:
    vcf="out.vcf.gz"
    vcfCsi="out.vcf.gz.csi"
    
    template 'bcftools_concat.sh'
}

// TODO code deduplication with bcftools_concat
process bcftools_concat_index {
  publishDir "$params.output", mode: 'link'

  input:
    tuple val(meta), path(gVcfs)
  output:
    tuple path(gVcf), path(gVcfCsi)
  script:
    gVcf="${meta.family_id}_${meta.individual_id}.g.vcf.gz"
    gVcfCsi="${meta.family_id}_${meta.individual_id}.g.vcf.gz.csi"
    
    template 'bcftools_concat_index.sh'
}

process bcftools_view_contig {
  input:
    tuple val(meta), path(gVcf), path(gVcfIndex)
  output:
    tuple val(meta), path(gVcfContig)
  script:
    gVcfContig="${meta.sample.family_id}_${meta.sample.individual_id}_${meta.contig}.g.vcf.gz"
    
    template 'bcftools_view_contig.sh'
}

process bcftools_view_chunk {
  input:
    tuple val(meta), path(gVcf), path(gVcfIndex)
  output:
    tuple val(meta), path(gVcfChunk), path(gVcfChunkIndex)
  script:
    bed="chunk_${meta.chunk.index}.bed"
    bedContent = meta.chunk.regions.collect { region -> "${region.chrom}\t${region.chromStart}\t${region.chromEnd}" }.join("\n")
    gVcfChunk="${meta.sample.family_id}_${meta.sample.individual_id}_${meta.chunk.index}.g.vcf.gz"
    gVcfChunkIndex="${gVcfChunk}.csi"
    
    template 'bcftools_view_chunk.sh'
}

// FIXME dedup with bcftools_view_chunk
process bcftools_view_chunk_vcf {
  input:
    tuple val(meta), path(vcf), path(vcfIndex)
  output:
    tuple val(meta), path(vcfChunk), path(vcfChunkIndex)
  script:
    bed="chunk_${meta.chunk.index}.bed"
    bedContent = meta.chunk.regions.collect { region -> "${region.chrom}\t${region.chromStart}\t${region.chromEnd}" }.join("\n")
    vcfChunk="chunk_${meta.chunk.index}.vcf.gz"
    vcfChunkIndex="${vcfChunk}.csi"
    
    template 'bcftools_view_chunk_vcf.sh'
}

process bcftools_index_count {
  input:
    tuple val(meta), path(vcfIndex)
  output:
    count
  script:
    template 'bcftools_index_count.sh'
}

process bcftools_index {
  input:
    tuple val(meta), path(vcf)
  output:
    tuple val(meta), path(vcfIndex)
  script:
    vcfIndex="${vcf}.csi"

    template 'bcftools_index.sh'
}