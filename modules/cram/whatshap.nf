include { createPedigree } from '../utils'

process whatshap {
  label 'whatshap'

  input:
    tuple val(meta), path(vcf), path(vcfIndex), path(vcfStats), path(crams), path(cramCrais)
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

    algorithm = params.snv.whatshap.algorithm
    internalDownsampling = params.snv.whatshap.internal_downsampling
    mappingQuality = params.snv.whatshap.mapping_quality
    onlySnvs = params.snv.whatshap.only_snvs
    ignoreReadGroups = params.snv.whatshap.ignore_read_groups
    errorRate = params.snv.whatshap.error_rate
    maximumErrorRate = params.snv.whatshap.maximum_error_rate
    threshold = params.snv.whatshap.threshold
    negativeThreshold = params.snv.whatshap.negative_threshold
    distrustGenotypes = params.snv.whatshap.distrust_genotype
    includeHomozygous = params.snv.whatshap.include_homozygous
    defaultGq = params.snv.whatshap.default_gq
    glRegularizer = params.snv.whatshap.gl_regularizer
    changedGenotypeList = params.snv.whatshap.changed_genotype_list
    recombinationList = params.snv.whatshap.recombination_list
    recombrate = params.snv.whatshap.recombrate
    genmap = params.snv.whatshap.genmap
    noGeneticHaplotyping = params.snv.whatshap.no_genetic_haplotyping
    usePedSamples = params.snv.whatshap.use_ped_samples
    useSupplementary = params.snv.whatshap.use_supplementary
    supplementaryDistance = params.snv.whatshap.supplementary_distance
    outputReadList = params.snv.whatshap.output_read_list

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