// TODO --bed seems to be broken: https://github.com/dnanexus-rnd/GLnexus/issues/279
process glnexus_merge {
  input:
    tuple val(meta), path(gVcfs)
  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex), path(vcfOutStats)
  shell:
    vcfOut="chunk_${meta.chunk.index}.vcf.gz"
    vcfOutIndex="${vcfOut}.csi"
    vcfOutStats="${vcfOut}.stats"

    config=params.sequencingMethod == "WES" ? "DeepVariantWES" : "DeepVariantWGS"

    template 'glnexus_merge.sh'
}
