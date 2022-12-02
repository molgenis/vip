include { createPedigree } from '../utils'

process inheritance {
  input:
    tuple val(meta), path(vcfPath), path(vcfPathCsi)
  output:
    tuple val(meta), path(vcfInheritancePath), path("${vcfInheritancePath}.csi")
  shell:
    id = "${vcfPath.simpleName}"
    order = "${meta.chunk.index}"
    vcfInheritancePath = "${id}_chunk${order}_inheritance.vcf.gz"
    probands = meta.probands.collect{ proband -> proband.individual_id}.join(",")
    pedigree = "pedigree.ped"
    pedigreeContent = createPedigree(meta.sampleSheet)
    template 'inheritance.sh'
}
