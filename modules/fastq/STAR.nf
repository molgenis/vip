nextflow.enable.dsl=2

/**
Uses a STAR reference index directory to map paired end fastq file to a BAM file. 
Input: meta variable containing all sample data to use further into the workflow
       forward read fastq file
       reverse read fastq file
       sample id
Output: meta variable containing all sample data to use further into the workflow
        mapped RNA BAM file of fastq files
        sample id
**/
process star_pe {
    label 'star_align_pe'
    input:
        tuple val(meta), path(fastq_r1), path(fastq_r2), val(sample_id)
    output:
        tuple val(meta), path("${sample_id}/Aligned.sortedByCoord.out.bam"), val(sample_id)
    script:
        """
        apptainer exec --no-mount home --bind \${TMPDIR} ${projectDir}/containers/star.sif \
        STAR --genomeDir ${projectDir}/rna_resources/refGenome \
        --runThreadN ${task.cpus} \
        --readFilesIn $fastq_r1  $fastq_r2 \
        --outSAMtype BAM SortedByCoordinate \
        --outFileNamePrefix ${sample_id}/
        """
}

/**
Uses a STAR reference index directory to map single end fastq file to a BAM file. 
Input: meta variable containing all sample data to use further into the workflow
       fastq read file
       sample id
Output: meta variable containing all sample data to use further into the workflow
        mapped RNA BAM file of fastq file
**/
process star_se {
    label 'star_align_se'
    input:
        tuple val(meta), path(fastq), val(sample_id)
    output:
        tuple val(meta), path("${sample_id}/Aligned.sortedByCoord.out.bam"), val(sample_id)
    script:
        """
        apptainer exec --no-mount home --bind \${TMPDIR} ${projectDir}/containers/star.sif \
        STAR --genomeDir ${projectDir}/rna_resources/refGenome \
        --runThreadN ${task.cpus} \
        --readFilesIn $fastq \
        --outSAMtype BAM SortedByCoordinate \
        --outFileNamePrefix ${sample_id}/
        """
}

/**
Uses samtools to sort a BAM file and create an index file to make it
usable in featureCounts
Input: meta variable containing all sample data to use further into the workflow
       RNA BAM file
       sample id
Output: meta variable containing all sample data to use further into the workflow
        path to sorted RNA BAM file
**/
process samtools{
    input:
        tuple val(meta), path(bam_file), val(sample_id)
    output:
        tuple val(meta), path("${sample_id}_sorted.bam")
    script:
    """
    apptainer exec --no-mount home --bind \${TMPDIR} ${projectDir}/containers/star.sif \
    samtools sort $bam_file -o "${sample_id}_sorted.bam"
    apptainer exec --no-mount home --bind \${TMPDIR} ${projectDir}/containers/star.sif \
    samtools index "${sample_id}_sorted.bam"
    """
}
