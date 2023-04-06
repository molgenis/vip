include { basename } from './utils'

process merge_gvcf {
  input:
    tuple val(meta), path(gVcfs), path(gVcfIndexes)
  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex), path(vcfOutStats)
  shell:
    basename = basename(meta)
    vcfOut = "${basename}_merged.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"
    refSeqFaiPath = params[meta.assembly].reference.fastaFai
    config=params.vcf.gvcf_merge_preset

    template 'merge_gvcf.sh'
}
