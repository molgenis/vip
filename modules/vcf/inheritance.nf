include { createPedigree } from '../utils'

process inheritance {
  input:
    tuple val(meta), path(vcfPath), path(vcfPathCsi)
  output:
    tuple val(meta), path(vcfInheritancePath), path("${vcfInheritancePath}.csi")
  shell:
    vcfInheritancePath = vcfFilteredPath = "${meta.project_id}_chunk_${meta.chunk.index}_inheritance.vcf.gz"
    probands = meta.probands.collect{ proband -> proband.individual_id}.join(",")
    pedigree = "${meta.project_id}.ped"
    pedigreeContent = createPedigree(meta.sampleSheet)
    template 'inheritance.sh'
}
