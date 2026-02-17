process mutect2_mito {
  label 'gatk_mutect2_mito'

  input:
    tuple val(meta), path(cram), path(cramCrai)

  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex), path(vcfOutStats)

  shell:
    refSeqPath = params[meta.project.assembly].reference.fasta
    reference = refSeqPath.substring(0, refSeqPath.lastIndexOf('.'))
    chrmName = params.cram.mitochondria.chrm_name

    vcfOut = "${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_chrm_snv.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"

    template 'mutect2_mito.sh'

  stub:
    vcfOut="${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_chrm_snv.vcf.gz"
    vcfOutIndex="${vcfOut}.csi"
    vcfOutStats="${vcfOut}.stats"

    """
    touch "${vcfOut}"
    touch "${vcfOutIndex}"
    echo -e "chr1\t248956422\t1234" > "${vcfOutStats}"
    """
}

process filtermutect2_mito {
  label 'gatk_filtermutect2_mito'

  input:
    tuple val(meta), path(vcf), path(vcfIndex)

  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex), path(vcfOutStats)

  shell:
    refSeqPath = params[meta.project.assembly].reference.fasta
    reference = refSeqPath.substring(0, refSeqPath.lastIndexOf('.'))

    vcfOut = "${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_chrm_snv.filtered.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"

  stub:
    vcfOut = "${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_chrm_snv.filtered.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"

    """
    touch "${vcfOut}"
    touch "${vcfOutIndex}"
    echo -e "chr1\t248956422\t1234" > "${vcfOutStats}"
    """
}