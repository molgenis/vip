process straglr_call {
  label 'straglr_call'

  publishDir "$params.output/intermediates", mode: 'link'

  input:
    tuple val(meta), path(cram), path(cramCrai)
  output:
    tuple val(meta), path(tsvOut), path(vcfOut), path(vcfOutIndex), path(vcfOutStats)
  shell:
    paramReference = params[meta.project.assembly].reference.fasta
    paramReferenceFai = params[meta.project.assembly].reference.fastaFai
    paramLoci = params.str.straglr[meta.project.assembly].loci
    paramMinSupport = params.str.straglr.min_support
    paramMinClusterSize = params.str.straglr.min_cluster_size
    sampleId = meta.sample.individual_id
    sampleSex = meta.sample.sex != null ? meta.sample.sex : ""
    haploidContigsMale = params.str.straglr.tsv2vcf.haploid_contigs_male

    vcfOut = "${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_str.vcf.gz"
    tsvOut = "straglr.tsv"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"
    
    template 'straglr_call.sh'

  stub:
    vcfOut = "${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_str.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"

    """
    touch "${vcfOut}"
    touch "${vcfOutIndex}"
    echo -e "chr1\t248956422\t1234" > "${vcfOutStats}"
    """
}