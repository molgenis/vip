process dorado {
	label 'dorado'
	publishDir '../vip_test_nf/', mode: 'link'

	input:
	path in

	output:
	path "${params.run}.bam"
  
  	shell:

	template "dorado.sh"


}  