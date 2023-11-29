process modkit {
	// Proccess bam files using Modkit tool

	label 'modkit'
	publishDir '../vip_test_nf/', mode: 'link'

	input:
	tuple val(meta), path(sorted_bam), path(sorted_bam_index)

	output:
	tuple val(meta), path(bed), path(summary_modkit), path(log_modkit)
  
  	shell:
	name = "${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}"
	bed = "${name}_cpg.bed"
	summary_modkit = "${name}_summary_modkit.txt"
	log_modkit = "${name}_modkit.log"
		
	template 'modkit.sh'

}  