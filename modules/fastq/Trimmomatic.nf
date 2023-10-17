nextflow.enable.dsl=2

/**
Process for Trimming of paired end fastq files, gets meta data variable, forward fastq read,
reverse fastq read and sample id and trimms bad quality reads and adapter sequences. Returns
meta variable, trimmed forward fastq read, trimmed reverse fastq read and sample id.
**/
process trimmomatic_pe {
    label 'trimmomatic_pe'
    input:
        tuple val(meta), path(fastq_r1), path(fastq_r2), val(sample)
    output:
        tuple val(meta), path("${sample}_R1_trimmed.fastq"), path("${sample}_R2_trimmed.fastq"), val(sample)
    script:
        """
        apptainer exec --no-mount home --bind \${TMPDIR} ${projectDir}/containers/trimmomatic.sif \
        java -jar /Trimmomatic-0.38/trimmomatic-0.38.jar \
        PE ${fastq_r1} ${fastq_r2} \
        "${sample}_R1_trimmed.fastq" output_forward_unpaired.fastq \
        "${sample}_R2_trimmed.fastq" output_reverse_unpaired.fastq \
        ILLUMINACLIP:NexteraPE-PE.fa:2:30:10 LEADING:5 TRAILING:5 SLIDINGWINDOW:5:10 MINLEN:50
        """
}

/**
Process for Trimming of single end fastq files, gets meta data variable, a fastq read,
 and sample id and trimms bad quality reads and adapter sequences. Returns meta variable, 
 trimmed  fastq read and sample id.
**/
process trimmomatic_se {
    label 'trimmomatic_se'
    input:
        tuple val(meta), path(fastq)
    output:
        tuple val(meta), path("trimmed_fastq")
    script:
        """
        apptainer exec --no-mount home --bind \${TMPDIR} ${projectDir}/containers/trimmomatic.sif \
        java -jar /Trimmomatic-0.38/trimmomatic-0.38.jar \
        SE ${fastq} \
        "trimmed.fastq" \
        ILLUMINACLIP:NexteraPE-PE.fa:2:30:10 LEADING:5 TRAILING:5 SLIDINGWINDOW:5:10 MINLEN:50
        """
}