process outrider_counts {
  label 'outrider_counts'

  publishDir "$params.output/intermediates", mode: 'link'
  
  input:
    tuple val(meta), path(bam), path(bai)

  output:
    tuple val(meta), path(outrider_counts)

  shell:
    sampleName = "${meta.sample.individual_id}"
    pairedEnd = "${meta.project.rna_paired_ended}" == "true" ? "TRUE" : "FALSE"
    strandSpecific = 1 //FIXME hardcoded
    
    outrider_counts = "${sampleName}_outrider_counts.tsv"

    template 'outrider_counts.sh'

  //stub:
    //TODO
}