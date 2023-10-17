 /**
Uses the scripts/outrider.R script to perform an OUTRIDER analysis on the
given count matrix
Input: meta variable containing all sample data to use further into the workflow
       count matrix containing samples to be analysed with OUTRIDER
Output: outrider results object containing results of analysis
 **/ 
 process outrider {
    label 'vcf_outrider'

    publishDir "$params.output/intermediates", mode: 'link'
    
    input:
        tuple val(meta), path(countMatrix)
    output:
        path "outrider.rds"
    script:
         """
         apptainer exec --no-mount home --bind \${TMPDIR} ${projectDir}/containers/drop1.3.3.sif \
         Rscript ${projectDir}/scripts/outrider.R \
         $countMatrix ${params.RNA.reference.counts} "outrider.rds"
         """
 }

/**
Uses the scripts/setResults.R script to create a tsv file containing the results
for the given sample
Input: meta variable containing all sample data to use further into the workflow
       outrider results object
       sample id
Output: meta variable containing all sample data to use further into the workflow
        tsv file containing all found OUTRIDER results for the given sample
**/
 process rnaResults {
    label 'vcf_rnaResults'

    publishDir "$params.output/intermediates", mode: 'link'

    input:
        tuple val(meta), path(outriderResults), val(sample)
    output:
        tuple val(meta), path("${sample}_outrider.tsv")
    script:
        """
        apptainer exec --no-mount home --bind \${TMPDIR} ${projectDir}/containers/drop1.3.3.sif \
        Rscript ${projectDir}/scripts/setResults.R $sample $outriderResults "${sample}_outrider.tsv"
        """
 }