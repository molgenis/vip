// FIXME set config to DeepVariantWES, DeepVariantWGS or DeepVariant_unfiltered (trio)
// --bed seems to be broken: https://github.com/dnanexus-rnd/GLnexus/issues/279
process glnexus_merge {
  input:
    tuple val(meta), path(gVcfs)
  output:
    tuple val(meta), path(vcf), path(vcfIndex)
  shell:
    vcf="chunk_${meta.chunk.index}.vcf.gz"
    vcfIndex="${vcf}.csi"

    template 'glnexus_merge.sh'
}
