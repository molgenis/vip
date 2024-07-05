process spectre_call {
  label 'spectre_call'

  publishDir "$params.output/intermediates", mode: 'link'

  input:
    tuple val(meta), path(cram), path(cramCrai), path(vcfData)
    
  output:
    tuple val(meta), path(tsvOut), path(vcfOut), path(vcfOutIndex), path(vcfOutStats)

  shell:
    vcfOut = "${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_cnv.vcf.gz"
    tsvOut = "${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_cnv.tsv"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"
    
    template 'spectre_call.sh'

  stub:
    vcfOut = "${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_cnv.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"

    """
    touch "${vcfOut}"
    touch "${vcfOutIndex}"
    echo -e "chr1\t248956422\t1234" > "${vcfOutStats}"
    """
}