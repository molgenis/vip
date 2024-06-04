process coverage {
  label 'coverage'
  
  publishDir "$params.output/intermediates", mode: 'link'

  input:
    tuple val(meta), path(cram), path(cramCrai)
  
  output:
    tuple val(meta), path(cramCoverageOut), path(cramDepthOut)
  
  shell:
    cramCoverageOut="${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_coverage.tsv.gz"
    cramDepthOut="${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_depth.tsv.gz"

    paramReference = params[meta.project.assembly].reference.fasta

    template 'coverage.sh'
  
  stub:
    cramCoverageOut="${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_coverage.tsv.gz"
		cramDepthOut="${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_depth.tsv.gz"

    """
    touch "${cramCoverageOut}"
    touch "${cramDepthOut}"
    """
}