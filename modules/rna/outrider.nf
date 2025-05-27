
/*
        outridercountsR="${projectDir}/outrider/featurecounts.R"
        mergecountsR="${projectDir}/outrider/mergecounts.R"
        outriderDatasetR="${projectDir}/outrider/create_outrider_dataset.R"
        outriderOptimR="${projectDir}/outrider/outrider_optim.R"
        mergeQFiles="${projectDir}/outrider/merge_qfiles.R"
        outriderR="${projectDir}/outrider/outrider.R"
*/
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

process merge_sample_counts {
  label 'merge_counts'

  publishDir "$params.output/intermediates", mode: 'link'
  
  input:
    tuple val(meta), path(counts)

  output:
    tuple val(meta), path(outputFiles)

  shell:
    pairedEnd = "${meta.project.rna_paired_ended}" == "true" ? "TRUE" : "FALSE"
    strandSpecific = 1 //FIXME hardcoded
    externalCounts = params.rna.external_counts
    externalCountsAmount = params.rna.external_counts_amount
    samplesheet = "${meta.project.id}_rna_samplesheet.tsv"

    //create outrider samplesheet
    def lines = []
    lines << "sampleID\tbamFile\tpairedEnd\tstrandSpecific\tvcf\texcludeFit"
    meta.project.samples.each { sample ->
        lines << "${sample.individual_id}\t${sample.rna_cram.data}\t${pairedEnd}\t${strandSpecific}\tNA\tFALSE"
    }
    samplesheetContent = lines.join('\n')

    outputFile = "FIXME"
    template 'merge_sample_counts.sh'

  //stub:
    //TODO
}