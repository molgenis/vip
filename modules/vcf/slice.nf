process slice {
  label 'vcf_slice'
  
  input:
    tuple val(meta), path(vcf), path(vcfIndex), path(cram)

  output:
    tuple val(meta), path(cramOut)

  shell:
    cramOut="${cram.simpleName}_sliced.cram"
    
    refSeqPath = params[meta.project.assembly].reference.fasta

    template 'slice.sh'

  stub:
    cramOut="${cram.simpleName}_sliced.cram"
    
    """
    touch "${cramOut}"
    """
}