process to_cram {
	// Sort bam files using SAMTools
	label "to_cram"
	publishDir "$params.output/intermediates", mode: 'link'

	input:
	tuple val(meta), path(sorted_bam), path(sorted_bam_index)

	output:
	tuple val(meta), path(cram), path(cramCrai), path(cramStats)
  
  	shell:
	reference=params[meta.project.assembly].reference.fasta 
	cram="${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}.cram"
    cramCrai="${cram}.crai"
    cramStats="${cram}.stats"

	template 'to_cram.sh'

}