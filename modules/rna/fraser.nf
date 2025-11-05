process fraser_counts {
  label 'fraser_counts'
  
  input:
    tuple val(meta), path(bams), path(bais)

  output:
    tuple val(meta), path(fraser_output)

  shell:
    pairedEnd = "${meta.project.rna_paired_ended}" == "true" ? "TRUE" : "FALSE"
    strandSpecific = 2 //FIXME hardcoded
    externalCounts = "/groups/umcg-gcc/tmp02/projects/vipt/umcg-bcharbon/rna/counts/exported_counts/Cells_-_Cultured_fibroblasts--GRCh38--gencode29/"
    externalCountsAmount = params.rna.external_counts_amount
    samplesheet = "${meta.project.id}_rna_samplesheet.tsv"

    //create fraser samplesheet
    def lines = []
    lines << "sampleID\tbamFile\tpairedEnd\tstrandSpecific\tvcf\texcludeFit"
    meta.project.samples.each { sample ->
        lines << "${sample.individual_id}\t${sample.rna_cram.data}\t${pairedEnd}\t${strandSpecific}\tNA\tFALSE"
    }
    samplesheetContent = lines.join('\n')

    assembly=meta.project.assembly
    refSeqPath = params[assembly].reference.fasta
    fraser_output = "${meta.project.id}_fraser"
    fraser_counts_script = params.rna.scripts.fraser.fraser_counts
    fraser_merge_counts_script = params.rna.scripts.fraser.fraser_merge_counts

    template 'fraser_count.sh'
}


process fraser {
  label 'fraser'

  publishDir "$params.output/intermediates", mode: 'link'
  
  input:
    tuple val(meta), path(counts)

  output:
    tuple val(meta), path(output)

  shell:
    pairedEnd = "${meta.project.rna_paired_ended}" == "true" ? "TRUE" : "FALSE"
    strandSpecific = 2 //FIXME hardcoded
    externalCounts = "/groups/umcg-gcc/tmp02/projects/vipt/umcg-bcharbon/rna/counts/exported_counts/Cells_-_Cultured_fibroblasts--GRCh38--gencode29/"
    externalCountsAmount = params.rna.external_counts_amount
    samplesheet = "${meta.project.id}_rna_samplesheet.tsv"

    //create fraser samplesheet
    def lines = []
    lines << "sampleID\tbamFile\tpairedEnd\tstrandSpecific\tvcf\texcludeFit"
    meta.project.samples.each { sample ->
        lines << "${sample.individual_id}\t${sample.rna_cram.data}\t${pairedEnd}\t${strandSpecific}\tNA\tFALSE"
    }
    samplesheetContent = lines.join('\n')
    fraser_script = params.rna.scripts.fraser.fraser
    assembly=meta.project.assembly
    refSeqPath = params[assembly].reference.fasta

    output = "${meta.project.id}_fraser"
    outputFile = "${meta.project.id}_fraser.tsv"

    template 'fraser.sh'
}