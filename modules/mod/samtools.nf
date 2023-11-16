process sort_bam {
publishDir "../vip_test_nf", mode: 'link'

	input:
	path in

	output:
	tuple path("small_X5_sorted.bam"), path("small_X5_sorted.bam.csi")

	shell:

	template 'samtools.sh'

}