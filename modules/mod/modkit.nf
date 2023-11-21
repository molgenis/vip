process modkit {
	label 'modkit'
	publishDir '../vip_test_nf/', mode: 'link'

	input:
	tuple path(in), path(index)

	output:
	tuple path("${params.run}_cpg.bed"), path("${params.run}_summary.txt"), path("${params.run}_modkit.log")
  
  	shell:
		template 'modkit.sh'

}  