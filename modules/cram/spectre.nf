process spectre_call {
  label 'spectre_call'

  publishDir "$params.output/intermediates", mode: 'link'

  input:
    tuple val(meta), path(cram), path(cramCrai)
    
  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex), path(vcfOutStats)

  shell:
    vcfOut = "${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_cnv.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"

    paramReference = params[meta.project.assembly].reference.fasta
    paramMetadata = params.cnv.spectre[meta.project.assembly].metadata
    paramBlacklist = params.cnv.spectre[meta.project.assembly].blacklist
    sampleId = meta.sample.individual_id
    sampleSex = meta.sample.sex
    
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