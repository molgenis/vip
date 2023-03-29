process manta_call {
  input:
    tuple val(key), val(meta), path(crams), path(cramCrais)
  output:
    tuple val(key), val(meta), path(vcfOut), path(vcfOutIndex), path(vcfOutStats)
  shell:
    project_id = key[0]
    chunk = key[1]
    assembly = key[2]

    refSeqPath = params[assembly].reference.fasta
    reference = refSeqPath.substring(0, refSeqPath.lastIndexOf('.')) 
    bed="${project_id}_${chunk.index}.bed"
    bedGz="${bed}.gz"
    bedContent = chunk.regions.collect { region -> "${region.chrom}\t${region.chromStart}\t${region.chromEnd}" }.join("\n")
    sequencingMethod = meta.sample.sequencing_method[0]

    vcfOut="${project_id}_${chunk.index}_sv.vcf.gz"
    vcfOutIndex="${vcfOut}.tbi"
    vcfOutStats="${vcfOut}.stats"

    template 'manta_call.sh'
}

process manta_call_publish {
  publishDir "$params.output/intermediates", mode: 'link'

  input:
    tuple val(project_id), path(vcfs), path(vcfIndexes)
  output:
    tuple path(vcfOut), path(vcfOutIndex)
  shell:
    vcfOut="${project_id}_sv.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"

    template 'publish.sh'
}