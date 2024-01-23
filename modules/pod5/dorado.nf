process dorado {
	// Basecall pod5 files using Dorado
	label 'dorado'
	publishDir "$params.output/intermediates", mode: 'link'

	input:
	tuple val(meta), path(pod5)

	output:
	tuple val(meta), path(bam)
  
  	shell:
	reference=params[params.assembly].reference.fasta
	bam="${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}.bam"

	template "dorado.sh"


}  