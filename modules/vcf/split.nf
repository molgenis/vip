include { basename } from './utils'

process split {
  label 'vcf_split'
  
  input:
    tuple val(meta), path(vcf), path(vcfIndex)
    
  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex), path(vcfOutStats)

  shell:
    basename = basename(meta)
    vcfOut = "${basename}.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"

    bed="${basename}.bed"
    bedContent = meta.chunk.regions.collect { region -> "${region.chrom}\t${region.chromStart}\t${region.chromEnd}" }.join("\n")

    template 'split.sh'
  
  stub:
    basename = basename(meta)
    vcfOut = "${basename}.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"

    """
    touch "${vcfOut}"
    touch "${vcfOutIndex}"
    echo -e "chr1\t248956422\t1234" > "${vcfOutStats}"
    """
}