process dorado {
	// Basecall pod5 files using Dorado
	label 'dorado'
	publishDir '../vip_test_nf/', mode: 'link'

	input:
	tuple val(meta), path(pod5)

	output:
	tuple val(meta), path(bam)
  
  	shell:
	bam="${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}.bam"

	template "dorado.sh"


}  