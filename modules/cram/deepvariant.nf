process deepvariant_call {
  input:
    tuple val(meta), path(cram), path(cramCrai)
  output:
    tuple val(meta), path(gVcf), path(gVcfIndex)
  shell:
    reference=params[params.assembly].reference.fasta
    bed="${meta.sample.individual_id}_${meta.chunk.index}.bed"
    bedContent = meta.chunk.regions.collect { region -> "${region.chrom}\t${region.chromStart}\t${region.chromEnd}" }.join("\n")
    
    vcf="${meta.sample.individual_id}_${meta.chunk.index}.vcf.gz"
    gVcf="${meta.sample.individual_id}_${meta.chunk.index}.g.vcf.gz"
    gVcfIndex="${gVcf}.tbi"

    template 'deepvariant_call.sh'
}

process deeptrio_call {
  input:
    tuple val(meta), path(cramChild), path(cramCraiChild), path(cramFather), path(cramCraiFather), path(cramMother), path(cramCraiMother)
  output:
    tuple val(meta), path(gVcfChild), path(gVcfChildIndex), path(gVcfFather), path(gVcfFatherIndex), path(gVcfMother), path(gVcfMotherIndex)
  shell:
    reference=params[params.assembly].reference.fasta
    bed="${meta.sample.individual_id}_${meta.chunk.index}.bed"
    bedContent = meta.chunk.regions.collect { region -> "${region.chrom}\t${region.chromStart}\t${region.chromEnd}" }.join("\n")
    
    vcfChild="${meta.sample.individual_id}_${meta.contig}.vcf.gz"
    vcfFather="${meta.sample.paternal_id}_${meta.contig}.vcf.gz"
    vcfMother="${meta.sample.maternal_id}_${meta.contig}.vcf.gz"
    gVcfChild="${meta.sample.individual_id}_${meta.contig}.g.vcf.gz"
    gVcfFather="${meta.sample.paternal_id}_${meta.contig}.g.vcf.gz"
    gVcfMother="${meta.sample.maternal_id}_${meta.contig}.g.vcf.gz"
    gVcfChildIndex="${gVcfChild}.tbi"
    gVcfFatherIndex="${gVcfFather}.tbi"
    gVcfMotherIndex="${gVcfMother}.tbi"

    template 'deeptrio_call.sh'
}

process deeptrio_call_duo_father {
  input:
    tuple val(meta), path(cramChild), path(cramCraiChild), path(cramFather), path(cramCraiFather)
  output:
    tuple val(meta), path(gVcfChild), path(gVcfChildIndex), path(gVcfFather), path(gVcfFatherIndex)
  shell:
    reference=params[params.assembly].reference.fasta
    bed="${meta.samples.proband.individual_id}_${meta.chunk.index}.bed"
    bedContent = meta.chunk.regions.collect { region -> "${region.chrom}\t${region.chromStart}\t${region.chromEnd}" }.join("\n")
    vcfChild="${meta.samples.proband.individual_id}_${meta.chunk.index}.vcf.gz"
    vcfFather="${meta.samples.proband.paternal_id}_${meta.chunk.index}.vcf.gz"
    gVcfChild="${meta.samples.proband.individual_id}_${meta.chunk.index}.g.vcf.gz"
    gVcfFather="${meta.samples.proband.paternal_id}_${meta.chunk.index}.g.vcf.gz"
    gVcfChildIndex="${gVcfChild}.tbi"
    gVcfFatherIndex="${gVcfFather}.tbi"

    template 'deeptrio_call_duo_father.sh'
}

process deeptrio_call_duo_mother {
  input:
    tuple val(meta), path(cramChild), path(cramCraiChild), path(cramMother), path(cramCraiMother)
  output:
    tuple val(meta), path(gVcfChild), path(gVcfChildIndex), path(gVcfMother), path(gVcfMotherIndex)
  shell:
    reference=params[params.assembly].reference.fasta
    bed="${meta.samples.proband.individual_id}_${meta.chunk.index}.bed"
    bedContent = meta.chunk.regions.collect { region -> "${region.chrom}\t${region.chromStart}\t${region.chromEnd}" }.join("\n")
    
    vcfChild="${meta.samples.proband.individual_id}_${meta.contig}.vcf.gz"
    vcfMother="${meta.samples.proband.maternal_id}_${meta.contig}.vcf.gz"
    gVcfChild="${meta.samples.proband.individual_id}_${meta.contig}.g.vcf.gz"
    gVcfMother="${meta.samples.proband.maternal_id}_${meta.contig}.g.vcf.gz"
    gVcfChildIndex="${gVcfChild}.tbi"
    gVcfMotherIndex="${gVcfMother}.tbi"

    template 'deeptrio_call_duo_mother.sh'
}