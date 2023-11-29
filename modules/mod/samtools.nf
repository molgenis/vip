process sort_bam {
	// Sort bam files using SAMTools
	label "sort_bam"
	publishDir "../vip_test_nf", mode: 'link'

	input:
	tuple val(meta), path(bam)

	output:
	tuple val(meta), path(sorted_bam), path(sorted_bam_index)
  
  	shell:
	sorted_bam="${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_sorted.bam"
	sorted_bam_index="${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_sorted.bam.csi"

	template 'samtools.sh'

}