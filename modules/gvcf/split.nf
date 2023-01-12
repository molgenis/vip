process split {
  input:
    tuple val(meta), path(vcf), path(vcfIndex)
  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex), path(vcfOutStats)
  shell:
    basename = "${meta.sample.project_id}_chunk_${meta.chunk.index}"
    extension = "${vcf.name.substring(vcf.simpleName.length())}" // for example .vcf.gz or .g.vcf.gz
    vcfOut = "${basename}${extension}"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"

    bed="${basename}.bed"
    bedContent = meta.chunk.regions.collect { region -> "${region.chrom}\t${region.chromStart}\t${region.chromEnd}" }.join("\n")

    template 'split.sh'
}