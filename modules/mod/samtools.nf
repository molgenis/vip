process sort_bam {
publishDir "../vip_test_nf", mode: 'link'

	input:
	path in

	output:
	tuple path("${params.run}_sorted.bam"), path("${params.run}_sorted.bam.csi")

	shell:

	template 'samtools.sh'

}