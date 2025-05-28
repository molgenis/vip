process slice_rna {
  label 'vcf_slice_rna'
  
  input:
    tuple val(meta), path(vcf), path(vcfIndex), path(cram)

  output:
    tuple val(meta), path(cramOut)

  shell:
    cramOut="${cram.simpleName}_rna_sliced.cram"
    
    refSeqPath = params[meta.project.assembly].reference.fasta

    template 'slice.sh'

  stub:
    cramOut="${cram.simpleName}_rna_sliced.cram"
    
    """
    touch "${cramOut}"
    """
}