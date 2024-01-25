process modkit {
	// Proccess bam files using Modkit tool

	label 'modkit'
	publishDir "$params.output/intermediates", mode: 'link'

	input:
	tuple val(meta), path(sorted_bam), path(sorted_bam_index)

	output:
	tuple val(meta), path(bedmethyl)
  
  	shell:
	refSeqPath = params[params.assembly].reference.fasta
    reference = refSeqPath.substring(0, refSeqPath.lastIndexOf('.'))
	name = "${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}"
	bedmethyl = "${name}.bedmethyl"
	converted_bam = "${name}_converted.bam"
	converted_bam_index = "${name}_converted.bam.csi"
	summary_modkit = "${name}_summary_modkit.txt"
	log_modkit = "${name}_modkit.log"
		
	template 'modkit.sh'

}  