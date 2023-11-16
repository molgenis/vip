process modkit {
	label 'modkit'
	publishDir '../vip_test_nf/', mode: 'link'

	input:
	tuple path(in), path(index)

	output:
	tuple path('small_X5_cpg.bed'), path("modkit_X5_summary.txt")
  
  	shell:
		template 'modkit.sh'

}  