include { createPedigree } from '../utils'

process whatshap {
  label 'whatshap'

  publishDir "$params.output/intermediates", mode: 'link'

  input:
    tuple val(meta), path(vcf), path(crams), path(cramCrais)
  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex), path(vcfOutStats)
  shell:
    //Workaround for https://github.com/whatshap/whatshap/issues/151
    paramReferenceGz = params[meta.project.assembly].reference.fasta
    paramReference = paramReferenceGz.substring(0, paramReferenceGz.lastIndexOf('.'))

    pedigree = "${meta.project.id}.ped"
    pedigreeContent = createPedigree(meta.project.samples)

    vcfOut = "${meta.project.id}_${meta.chunk.index}_phased.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"
    
    template 'whatshap.sh'

  stub:    
    vcfOut = "${meta.project.id}_${meta.chunk.index}_phased.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"

    """
    touch "${vcfOut}"
    touch "${vcfOutIndex}"
    echo -e "chr1\t248956422\t1234" > "${vcfOutStats}"
    """
}