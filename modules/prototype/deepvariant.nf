process deepvariant_call {
  input:
    tuple val(meta), path(reference), path(referenceFai), path(referenceGzi), path(cram), path(cramCrai)
  output:
    tuple val(meta), path(gVcf)
  script:
    vcf="${meta.family_id}_${meta.individual_id}_${meta.contig}.vcf.gz"
    gVcf="${meta.family_id}_${meta.individual_id}_${meta.contig}.g.vcf.gz"
    """
    ${CMD_DEEPVARIANT} \
      --model_type=${meta.seq_method} \
      --ref=${reference} \
      --reads=${cram} \
      --regions ${meta.contig} \
      --sample_name ${meta.family_id}_${meta.individual_id} \
      --output_vcf="${vcf}" \
      --output_gvcf="${gVcf}" \
      --intermediate_results_dir ${TMPDIR} \
      --num_shards=${task.cpus}
    """
}

process deeptrio_call {
  input:
    tuple val(meta), path(reference), path(referenceFai), path(referenceGzi), path(cramChild), path(cramCraiChild), path(cramFather), path(cramCraiFather), path(cramMother), path(cramCraiMother)
  output:
    tuple val(meta), path(gVcfChild), path(gVcfFather), path(gVcfMother)
  script:
    vcfChild="${meta.family_id}_${meta.individual_id}_${meta.contig}.vcf.gz"
    vcfFather="${meta.family_id}_${meta.paternal_id}_${meta.contig}.vcf.gz"
    vcfMother="${meta.family_id}_${meta.maternal_id}_${meta.contig}.vcf.gz"
    gVcfChild="${meta.family_id}_${meta.individual_id}_${meta.contig}.g.vcf.gz"
    gVcfFather="${meta.family_id}_${meta.paternal_id}_${meta.contig}.g.vcf.gz"
    gVcfMother="${meta.family_id}_${meta.maternal_id}_${meta.contig}.g.vcf.gz"
    """
    ${CMD_DEEPTRIO} \
      --model_type=${meta.seq_method} \
      --ref=${reference} \
      --reads_child=${cramChild} \
      --reads_parent1=${cramFather} \
      --reads_parent2=${cramMother} \
      --regions ${meta.contig} \
      --sample_name_child=${meta.family_id}_${meta.individual_id} \
      --sample_name_parent1=${meta.family_id}_${meta.paternal_id} \
      --sample_name_parent2=${meta.family_id}_${meta.maternal_id} \
      --output_vcf_child="${vcfChild}" \
      --output_vcf_parent1="${vcfFather}" \
      --output_vcf_parent2="${vcfMother}" \
      --output_gvcf_child="${gVcfChild}" \
      --output_gvcf_parent1="${gVcfFather}" \
      --output_gvcf_parent2="${gVcfMother}" \
      --intermediate_results_dir ${TMPDIR} \
      --num_shards=${task.cpus}
    """
}

process deeptrio_call_duo_father {
  input:
    tuple val(meta), path(reference), path(referenceFai), path(referenceGzi), path(cramChild), path(cramCraiChild), path(cramFather), path(cramCraiFather)
  output:
    tuple val(meta), path(gVcfChild), path(gVcfFather)
  script:
    vcfChild="${meta.family_id}_${meta.individual_id}_${meta.contig}.vcf.gz"
    vcfFather="${meta.family_id}_${meta.paternal_id}_${meta.contig}.vcf.gz"
    gVcfChild="${meta.family_id}_${meta.individual_id}_${meta.contig}.g.vcf.gz"
    gVcfFather="${meta.family_id}_${meta.paternal_id}_${meta.contig}.g.vcf.gz"
    """
    ${CMD_DEEPTRIO} \
      --model_type=${meta.seq_method} \
      --ref=${reference} \
      --reads_child=${cramChild} \
      --reads_parent1=${cramFather} \
      --regions ${meta.contig} \
      --sample_name_child=${meta.family_id}_${meta.individual_id} \
      --sample_name_parent1=${meta.family_id}_${meta.paternal_id} \
      --output_vcf_child="${vcfChild}" \
      --output_vcf_parent1="${vcfFather}" \
      --output_gvcf_child="${gVcfChild}" \
      --output_gvcf_parent1="${gVcfFather}" \
      --intermediate_results_dir ${TMPDIR} \
      --num_shards=${task.cpus}
    """
}

process deeptrio_call_duo_mother {
  input:
    tuple val(meta), path(reference), path(referenceFai), path(referenceGzi), path(cramChild), path(cramCraiChild), path(cramMother), path(cramCraiMother)
  output:
    tuple val(meta), path(gVcfChild), path(gVcfMother)
  script:
    vcfChild="${meta.family_id}_${meta.individual_id}_${meta.contig}.vcf.gz"
    vcfMother="${meta.family_id}_${meta.maternal_id}_${meta.contig}.vcf.gz"
    gVcfChild="${meta.family_id}_${meta.individual_id}_${meta.contig}.g.vcf.gz"
    gVcfMother="${meta.family_id}_${meta.maternal_id}_${meta.contig}.g.vcf.gz"
    """
    ${CMD_DEEPTRIO} \
      --model_type=${meta.seq_method} \
      --ref=${reference} \
      --reads_child=${cramChild} \
      --reads_parent1=${cramMother} \
      --regions ${meta.contig} \
      --sample_name_child=${meta.family_id}_${meta.individual_id} \
      --sample_name_parent1=${meta.family_id}_${meta.maternal_id} \
      --output_vcf_child="${vcfChild}" \
      --output_vcf_parent1="${vcfMother}" \
      --output_gvcf_child="${gVcfChild}" \
      --output_gvcf_parent1="${gVcfMother}" \
      --intermediate_results_dir ${TMPDIR} \
      --num_shards=${task.cpus}
    """
}