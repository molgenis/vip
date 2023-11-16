process dorado {
	label 'dorado'
	publishDir '../vip_test_nf/', mode: 'link'

	input:
	path in

	output:
	path 'small_X5.bam'
  
  	shell:
  """
  ${CMD_DORADO} basecaller ${params.dorado_model} $in --modified-bases 5mCG_5hmCG --reference ${params.reference_g1k_v37} > small_X5.bam
  """

}  