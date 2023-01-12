include { basename } from './utils'
include { createPedigree } from '../utils'

process inheritance {
  input:
    tuple val(meta), path(vcf), path(vcfIndex), path(vcfStats)
  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex), path(vcfOutStats)
  shell:
    basename = basename(meta)
    vcfOut = "${basename}_inheritanced.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"

    probands = meta.probands.collect{ proband -> proband.individual_id}.join(",")
    pedigree = "${meta.project_id}.ped"
    pedigreeContent = createPedigree(meta.sampleSheet)

    template 'inheritance.sh'
}
