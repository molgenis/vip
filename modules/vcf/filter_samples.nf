include { basename } from './utils'

process filter_samples {
  input:
    tuple val(meta), path(vcf), path(vcfIndex), path(vcfStats)
  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex), path(vcfOutStats)
  shell:
    basename = basename(meta)
    vcfOut = "${basename}_filtered_samples.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"
    
    template 'filter_samples.sh'
}
