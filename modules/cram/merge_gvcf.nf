include { basename } from './utils'

// TODO --bed seems to be broken: https://github.com/dnanexus-rnd/GLnexus/issues/279
process merge_gvcf {
  input:
    tuple val(meta), path(gVcfs), path(gVcfIndexes)
  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex), path(vcfOutStats)
  shell:
    basename = basename(meta.samples[0])
    vcfOut = "${basename}_merged.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"

    config=params.vcf.gvcf_merge_preset

    template 'merge_gvcf.sh'
}
