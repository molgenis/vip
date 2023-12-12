process methplotlib {
	// Proccess bed files using methplotlib tool

	label 'methplotlib'
	publishDir '../vip_test_nf/', mode: 'link'

	input:
	tuple val(meta), path(bed), val(region)

	output:
	tuple val(meta), path(png)
  
  	shell:
	name = "${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}"
	png = "${name}_${region.replaceAll(/:/, "-")}.png"
	
		
	template 'methplotlib.sh'

}  