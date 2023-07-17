process straglr_call {
  publishDir "$params.output/intermediates", mode: 'link'

  input:
    tuple val(meta), path(cram), path(cramCrai)
  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex)
  shell:
    reference = params[meta.sample.assembly].reference.fasta
    loci = params.cram.straglr[meta.sample.assembly].loci
    minSupport = params.cram.straglr.minSupport
    minClusterSize = params.cram.straglr.minClusterSize
    sampleId = meta.sample.individual_id
    sampleSex = meta.sample.sex

    vcfOut = "${meta.sample.project_id}_${meta.sample.family_id}_${meta.sample.individual_id}_str.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"
    
    template 'stragler_call.sh'
}