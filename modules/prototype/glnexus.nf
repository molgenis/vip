// FIXME set config to DeepVariantWES, DeepVariantWGS or DeepVariant_unfiltered (trio)
process glnexus_merge {
  input:
    tuple val(meta), path(gVcfs)
  output:
    tuple val(meta), path(bcf)
  script:
    bcf="${meta.contig}.bcf"
    """
    ${CMD_GLNEXUS} \
      --dir ${TMPDIR}/glnexus \
      --config DeepVariantWES \
      --threads ${task.cpus} \
      ${gVcfs} > ${bcf}
    """
}
