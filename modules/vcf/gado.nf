include { getProbandHpoIds; areProbandHpoIdsIndentical } from './utils'
process gado {
  label 'gado'

  input:
    val(meta)

  output:
    tuple val(meta), path(gadoScores)

  shell:
    gadoGenesPath = params.vcf.annotate.gado_genes
    gadoScores = "./gado/all_samples.txt"

    gadoHpoPath = params.vcf.annotate.gado_hpo
    gadoPredictInfoPath = params.vcf.annotate.gado_predict_info
    gadoPredictMatrixPath = params.vcf.annotate.gado_predict_matrix
    areProbandHpoIdsIndentical = areProbandHpoIdsIndentical(meta.project.samples)
    gadoHpoIds = getProbandHpoIds(meta.project.samples).join(",")

    template 'gado.sh'

  stub:
    gadoScores = "./gado/all_samples.txt"

    """
    mkdir -p "./gado"
    touch "${gadoScores}"
    """
}
