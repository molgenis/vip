process classify_samples {
  input:
    tuple val(meta), path(vcfPath), path(vcfPathCsi)
  output:
    tuple val(meta), path(vcfSamplesClassifiedPath), path("${vcfSamplesClassifiedPath}.csi")
  shell:
    id = "${vcfPath.simpleName}"
    order = "${meta.chunk.index}"
    vcfSamplesClassifiedPath = "${id}_chunk${order}_samples_classified.vcf.gz"
    probands = meta.probands.collect{ proband -> proband.individual_id}.join(",")
    template 'classify_samples.sh'
}
