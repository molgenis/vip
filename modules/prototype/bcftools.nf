// FIXME add meta input and determine output name from meta
process bcftools_concat {
  input:
    tuple val(meta), path(bcfs)
  output:
    tuple val(meta), path(vcf)
  script:
    vcf="out.vcf.gz"
    """
    ${CMD_BCFTOOLS} concat \
    --output-type z9 \
    --output "${vcf}" \
    --no-version \
    --threads "${task.cpus}" ${bcfs}
    """
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
    """
    ${CMD_BCFTOOLS} concat \
    --output-type z9 \
    --output "${gVcf}" \
    --no-version \
    --threads "${task.cpus}" ${gVcfs}
    
    ${CMD_BCFTOOLS} index "${gVcf}"
    """
}

process bcftools_view_contig {
  input:
    tuple val(meta), path(gVcf), path(gVcfIndex)
  output:
    tuple val(meta), path(gVcfContig)
  script:
    gVcfContig="${meta.sample.family_id}_${meta.sample.individual_id}_${meta.contig}.g.vcf.gz"
    """
    ${CMD_BCFTOOLS} view --regions "${meta.contig}" --output-type z --output-file "${gVcfContig}" --no-version --threads "${task.cpus}" "${gVcf}"
    """
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
    """
    echo -e "${bedContent}" > "${bed}"

    ${CMD_BCFTOOLS} view --regions "${bed}" --output-type z --output-file "${gVcfChunk}" --no-version --threads "${task.cpus}" "${gVcf}"
    ${CMD_BCFTOOLS} index "${gVcfChunk}"
    """
}

process bcftools_index {
  input:
    tuple val(meta), path(vcf)
  output:
    tuple val(meta), path(vcfIndex)
  script:
    vcfIndex="${vcf}.csi"
    """
    ${CMD_BCFTOOLS} index --threads "${task.cpus}" "${vcf}"
    """
}