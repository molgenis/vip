process featureCounts {
    input:
        tuple val(meta), val(bamFile), val(sample)
    output:
        tuple val(meta), path("${sample}_countMatrix.txt"), val(sample)
    script:
        """
        apptainer exec --no-mount home --bind \${TMPDIR} ${projectDir}/containers/featureCounts.sif featureCounts \
        -a ${projectDir}/rna_resources/gencode.v34lift37.annotation.gtf -T $task.cpus -o "${sample}_countMatrix.txt" $bamFile
        """
}

process cut {
    input:
        tuple val(meta), path(countMatrix), val(sample)
    output:
        tuple val(meta), path("${sample}_countMatrix_cut.txt"), val(sample)
    script:
        """
        cut -f1,7,8,9,10,11,12 $countMatrix > ${sample}_countMatrix_cut.txt
        """
}

process createMatrix {
    input:
        tuple val(meta), path(countMatrix), val(sample), path(matrixFile)
    output:
        tuple val(meta), path(matrixFile)
    script:
        """
        apptainer exec --no-mount home --bind \${TMPDIR} ${projectDir}/containers/drop1.3.3.sif \
        Rscript ${projectDir}/scripts/createMatrix.R $countMatrix $sample $matrixFile
        """
}