/**
Use featureCounts to convert a bam file into a count matrix
Input: meta variable containing all sample data to use further into the workflow
       BAM file to be converted
       sample id
Output: meta variable containing all sample data to use further into the workflow
        count matrix created from BAM file
        sample id
**/
process featureCounts {
    input:
        tuple val(meta), val(bamFile), val(sample)
    output:
        tuple val(meta), path("${sample}_countMatrix.txt"), val(sample)
    script:
        """
        apptainer exec --no-mount home --bind \${TMPDIR} ${projectDir}/containers/featureCounts.sif featureCounts \
        -a ${params.RNA.reference.gtf} -T $task.cpus -s 1 -o "${sample}_countMatrix.txt" $bamFile
        """
}

/**
Removes info lines from countmatrix created by featureCounts so it can 
be used in OUTRIDER
Input: meta variable containing all sample data to use further into the workflow
       featureCounts created count matrix
       sample id
Output: meta variable containing all sample data to use further into the workflow
        OUTRIDER ready count matrix
        sample id
**/
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

/**
Combines all count matrix into one matrix to be merged with control count data
for an OUTRIDER analysis
Input: meta variable containing all sample data to use further into the workflow
       count matrix
       sample id
       template file for combined matrix
Output: meta variable containing all sample data to use further into the workflow
        updated combined count matrix
**/
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