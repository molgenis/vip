include { basename } from './utils'

process normalize {
  label 'vcf_normalize'
  
  input:
    tuple val(meta), path(vcf), path(vcfIndex), path(vcfStats)

  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex), path(vcfOutStats)

  shell:
    basename = basename(meta)
    vcfOut = "${basename}_normalized.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"
    
    refSeqPath = params[meta.project.assembly].reference.fasta
    
    template 'normalize.sh'
  
  stub:
    basename = basename(meta)
    vcfOut = "${basename}_normalized.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"

    """
    touch "${vcfOut}"
    touch "${vcfOutIndex}"
    echo -e "chr1\t248956422\t1234" > "${vcfOutStats}"
    """
}
