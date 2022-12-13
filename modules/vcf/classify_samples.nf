process classify_samples {
  input:
    tuple val(meta), path(vcfPath), path(vcfPathCsi)
  output:
    tuple val(meta), path(vcfSamplesClassifiedPath), path("${vcfSamplesClassifiedPath}.csi")
  shell:
    vcfSamplesClassifiedPath = "${meta.project_id}_chunk_${meta.chunk.index}_classified_samples.vcf.gz"
    probands = meta.probands.collect{ proband -> proband.individual_id}.join(",")
    template 'classify_samples.sh'
}
