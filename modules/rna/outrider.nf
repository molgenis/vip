process outrider_counts {
  label 'outrider_counts'
  
  input:
    tuple val(meta), path(bam), path(bai)

  output:
    tuple val(meta), path(outrider_counts)

  shell:
    sampleName = "${meta.sample.individual_id}"
    pairedEnd = "${meta.project.rna_paired_ended}" == "true" ? "TRUE" : "FALSE"
    strandSpecific = 2 //FIXME hardcoded

    assembly=meta.project.assembly
    refSeqPath = params[assembly].reference.fasta

    outrider_counts = "${sampleName}_outrider_counts.tsv"
    outrider_counts_script = params.rna.scripts.outrider.outrider_count;

    template 'outrider_counts.sh'
}

process outrider_create_dataset {
  label 'outrider_create_dataset'
  
  input:
    tuple val(meta), path(counts)

  output:
    tuple val(meta), path(outriderDataset), path(qvalues)

  shell:
    pairedEnd = "${meta.project.rna_paired_ended}" == "true" ? "TRUE" : "FALSE"
    strandSpecific = 2 //FIXME hardcoded
    externalCounts = params.rna.external_counts
    externalCountsAmount = params.rna.external_counts_amount
    samplesheet = "${meta.project.id}_rna_samplesheet.tsv"
    assembly=meta.project.assembly

    //create outrider samplesheet
    def lines = []
    lines << "sampleID\tbamFile\tpairedEnd\tstrandSpecific\tvcf\texcludeFit"
    meta.project.samples.each { sample ->
        lines << "${sample.individual_id}\t${sample.rna_cram.data}\t${pairedEnd}\t${strandSpecific}\tNA\tFALSE"
    }
    samplesheetContent = lines.join('\n')

    outriderDataset = "outrider.rds"
    qvalues = "qvalues.txt"

    outrider_create_dataset_script = params.rna.scripts.outrider.outrider_create_dataset;
    outrider_merge_counts_script = params.rna.scripts.outrider.outrider_merge_counts;
    template 'create_dataset.sh'
}

process outrider_optimize {
  label 'outrider_optimize'
  
  input:
    tuple val(meta), path(outriderDataset), path(qValuesFile), val(qValue)

  output:
    tuple val(meta), path(outriderDataset), path(qValuesFile), path(outputFile)

  shell:
    pairedEnd = "${meta.project.rna_paired_ended}" == "true" ? "TRUE" : "FALSE"
    strandSpecific = 2 //FIXME hardcoded
    externalCounts = params.rna.external_counts
    externalCountsAmount = params.rna.external_counts_amount
    samplesheet = "${meta.project.id}_rna_samplesheet.tsv"
    assembly=meta.project.assembly

    //create outrider samplesheet
    def lines = []
    lines << "sampleID\tbamFile\tpairedEnd\tstrandSpecific\tvcf\texcludeFit"
    meta.project.samples.each { sample ->
        lines << "${sample.individual_id}\t${sample.rna_cram.data}\t${pairedEnd}\t${strandSpecific}\tNA\tFALSE"
    }
    samplesheetContent = lines.join('\n')
    outrider_optimize_script = params.rna.scripts.outrider.outrider_optimize;

    outputFile = "${qValue}_endim.tsv"

    template 'optimize.sh'
}

process outrider {
  label 'outrider'

  publishDir "$params.output/intermediates", mode: 'link'
  
  input:
    tuple val(meta), path(outrider_dataset), path(ndimFiles)

  output:
    tuple val(meta), path(fullOutputFile)

  shell:
    pairedEnd = "${meta.project.rna_paired_ended}" == "true" ? "TRUE" : "FALSE"
    strandSpecific = 2 //FIXME hardcoded
    externalCounts = params.rna.external_counts
    externalCountsAmount = params.rna.external_counts_amount
    samplesheet = "${meta.project.id}_rna_samplesheet.tsv"
    assembly=meta.project.assembly

    //create outrider samplesheet
    def lines = []
    lines << "sampleID\tbamFile\tpairedEnd\tstrandSpecific\tvcf\texcludeFit"
    meta.project.samples.each { sample ->
        lines << "${sample.individual_id}\t${sample.rna_cram.data}\t${pairedEnd}\t${strandSpecific}\tNA\tFALSE"
    }
    samplesheetContent = lines.join('\n')

    outputRds = "final_outrider.rds"
    outputFile = "outrider_output.tsv"
    fullOutputFile = "combined_samples_outrider_output.tsv"

    outrider_merge_q_files_script = params.rna.scripts.outrider.outrider_merge_q_files;
    outrider_script = params.rna.scripts.outrider.outrider;
    template 'outrider.sh'
}