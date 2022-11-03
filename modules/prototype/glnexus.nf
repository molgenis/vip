// FIXME set config to DeepVariantWES, DeepVariantWGS or DeepVariant_unfiltered (trio)
// --bed seems to be broken: https://github.com/dnanexus-rnd/GLnexus/issues/279
process glnexus_merge {
  input:
    tuple val(meta), path(gVcfs)
  output:
    tuple val(meta), path(vcf), path(vcfIndex)
  script:
    vcf="chunk_${meta.chunk.index}.vcf.gz"
    vcfIndex="${vcf}.csi"
    """
    ${CMD_GLNEXUS} \
      --dir ${TMPDIR}/glnexus \
      --config DeepVariantWGS \
      --threads ${task.cpus} \
      ${gVcfs} | \
      ${CMD_BCFTOOLS} view --output-type z --output-file ${vcf} --no-version --threads "${task.cpus}"

    ${CMD_BCFTOOLS} index --threads "${task.cpus}" ${vcf}
    """
}
