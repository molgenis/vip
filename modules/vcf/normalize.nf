include { basename } from './utils'

process normalize {
  input:
    tuple val(meta), path(vcf), path(vcfIndex), path(vcfStats)
  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex), path(vcfOutStats)
  shell:
    basename = basename(meta)
    vcfOut = "${basename}_normalized.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"
    
    refSeqPath = params[params.assembly].reference.fasta
    
    template 'normalize.sh'
}
