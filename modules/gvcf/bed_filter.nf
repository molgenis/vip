include { basename } from './utils'

process bed_filter {
  label 'bed_filter'
  
  input:
    tuple val(meta), path(bed), path(vcf), path(vcfIndex)

  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex), path(vcfOutStats)

  shell:
    basename = basename(meta)
    vcfOut = "${meta.project.id}_bed_filtered.g.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"

    template 'bed_filter.sh'
  
  stub:
    basename = basename(meta)
    vcfOut = "${basename}_bed_filtered.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"

    """
    touch "${vcfOut}"
    touch "${vcfOutIndex}"
    echo -e "chr1\t248956422\t1234" > "${vcfOutStats}"
    """
}