process merge {  
  input:
    tuple val(meta), path(vcfs), path(vcfIndexes)
  output:
    tuple val(meta), path(vcf), path("${vcf}.csi")
  shell:
    vcf="${meta.project_id}.vcf.gz"
    
    template 'merge.sh'
}