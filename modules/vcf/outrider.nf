 process outrider {
     input:
         tuple val(meta), path(countMatrix)
     output:
         path "outrider.tsv"
     script:
         """
         apptainer exec --no-mount home --bind \${TMPDIR} ${projectDir}/containers/drop1.3.3.sif \
         Rscript ${projectDir}/scripts/outrider.R \
         $countMatrix ${projectDir}/rna_resources/geneCounts.tsv "outrider.tsv"
         """
 }

 process rnaResults {
    input:
        tuple val(meta), val(sample), path(outriderResults)
    output:
        tuple val(meta), path("{sample}_outrider.tsv")
    script:
        """
        apptainer exec --no-mount home --bind \${TMPDIR} ${projectDir}/containers/drop1.3.3.sif \
        Rscript ${projectDir}/scripts/setResults.R $sample $outriderResults "${sample}_outrider.tsv"
        """
 }