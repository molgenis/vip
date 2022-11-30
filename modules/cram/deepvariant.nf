//FIXME parallel: Error: Output is incomplete. Cannot append to buffer file in /local/1443534/. Is the disk full?
process deepvariant_call {
  input:
    tuple val(meta), path(cram), path(cramCrai)
  output:
    tuple val(meta), path(gVcf)
  script:
    reference=params[params.assembly].reference.fasta
    bed="${meta.sample.family_id}_${meta.sample.individual_id}_${meta.chunk.index}.bed"
    bedContent = meta.chunk.regions.collect { region -> "${region.chrom}\t${region.chromStart}\t${region.chromEnd}" }.join("\n")
    vcf="${meta.sample.family_id}_${meta.sample.individual_id}_${meta.chunk.index}.vcf.gz"
    gVcf="${meta.sample.family_id}_${meta.sample.individual_id}_${meta.chunk.index}.g.vcf.gz"

    template 'deepvariant_call.sh'
}

process deeptrio_call {
  input:
    tuple val(meta), path(reference), path(referenceFai), path(referenceGzi), path(cramChild), path(cramCraiChild), path(cramFather), path(cramCraiFather), path(cramMother), path(cramCraiMother)
  output:
    tuple val(meta), path(gVcfChild), path(gVcfFather), path(gVcfMother)
  script:
    vcfChild="${meta.sample.family_id}_${meta.sample.individual_id}_${meta.contig}.vcf.gz"
    vcfFather="${meta.sample.family_id}_${meta.sample.paternal_id}_${meta.contig}.vcf.gz"
    vcfMother="${meta.sample.family_id}_${meta.sample.maternal_id}_${meta.contig}.vcf.gz"
    gVcfChild="${meta.sample.family_id}_${meta.sample.individual_id}_${meta.contig}.g.vcf.gz"
    gVcfFather="${meta.sample.family_id}_${meta.sample.paternal_id}_${meta.contig}.g.vcf.gz"
    gVcfMother="${meta.sample.family_id}_${meta.sample.maternal_id}_${meta.contig}.g.vcf.gz"
    
    template 'deeptrio_call.sh'
}

process deeptrio_call_duo_father {
  input:
    tuple val(meta), path(reference), path(referenceFai), path(referenceGzi), path(cramChild), path(cramCraiChild), path(cramFather), path(cramCraiFather)
  output:
    tuple val(meta), path(gVcfChild), path(gVcfFather)
  script:
    vcfChild="${meta.sample.family_id}_${meta.sample.individual_id}_${meta.contig}.vcf.gz"
    vcfFather="${meta.sample.family_id}_${meta.sample.paternal_id}_${meta.contig}.vcf.gz"
    gVcfChild="${meta.sample.family_id}_${meta.sample.individual_id}_${meta.contig}.g.vcf.gz"
    gVcfFather="${meta.sample.family_id}_${meta.sample.paternal_id}_${meta.contig}.g.vcf.gz"

    template 'deeptrio_call_duo_father.sh'
}

process deeptrio_call_duo_mother {
  input:
    tuple val(meta), path(reference), path(referenceFai), path(referenceGzi), path(cramChild), path(cramCraiChild), path(cramMother), path(cramCraiMother)
  output:
    tuple val(meta), path(gVcfChild), path(gVcfMother)
  script:
    vcfChild="${meta.sample.family_id}_${meta.sample.individual_id}_${meta.contig}.vcf.gz"
    vcfMother="${meta.sample.family_id}_${meta.sample.maternal_id}_${meta.contig}.vcf.gz"
    gVcfChild="${meta.sample.family_id}_${meta.sample.individual_id}_${meta.contig}.g.vcf.gz"
    gVcfMother="${meta.sample.family_id}_${meta.sample.maternal_id}_${meta.contig}.g.vcf.gz"
    
    template 'deeptrio_call_duo_mother.sh'
}