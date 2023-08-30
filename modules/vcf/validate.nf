process validate {
  label 'vcf_validate'
  
  input:
    tuple val(meta), path(vcf)

  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex), path(vcfOutStats)

  shell:
    samplesFileData = meta.project.samples.collect { sample -> sample.individual_id }.join("\n")

    vcfOut = "${meta.project.id}_validated.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"

    template 'validate.sh'
  
  stub:
    vcfOut = "${meta.project.id}_validated.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"

    """
    touch "${vcfOut}"
    touch "${vcfOutIndex}"
    echo -e "chr1\t248956422\t1234" > "${vcfOutStats}"
    """
}