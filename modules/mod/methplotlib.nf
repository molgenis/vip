process methplotlib {
	// Proccess bed files using methplotlib tool

	label 'methplotlib'
	publishDir "$params.output/intermediates", mode: 'link'

	input:
	tuple val(meta), path(bed)

	output:
	tuple val(meta), path(png)
  
  	shell:
	name = "${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}"
	png = "${name}_chrX_147909919_147953125.png"
	region = "chrX:147909919-147953125"
		
	// template 'methplotlib.sh'

	"""
	echo ${region}
	"""

}  