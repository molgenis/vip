process slice {  
  input:
    tuple val(meta), path(vcf), path(vcfIndex), path(cram)
  output:
    tuple val(meta), path(cramOut)
  shell:
    cramOut="${cram.simpleName}_sliced.cram"
    
    refSeqPath = params[meta.assembly].reference.fasta

    template 'slice.sh'
}