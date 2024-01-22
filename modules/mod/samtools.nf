process sort_bam {
	// Sort bam files using SAMTools
	label "sort_bam"
	publishDir "$params.output/intermediates", mode: 'link'

	input:
	tuple val(meta), path(bam)

	output:
	tuple val(meta), path(sortedBam), path(sortedBamIndex), path(sortedBamStats)
  
  	shell:
	sortedBam="${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_sorted.bam"
	sortedBamIndex="${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_sorted.bam.csi"
	sortedBamStats="${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_sorted.bam.stats"

	template 'samtools.sh'

}