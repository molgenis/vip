process samtools_index {
  input:
    tuple val(meta), path(cram)
  output:
    tuple val(meta), path(cramIndex)
  shell:
    cramIndex=cram.name.endsWith('.cram') ? "${cram}.crai" : "${cram}.bai"

    template 'samtools_index.sh'
}

//add sample name to cram by replacing the read group:
//to make Manta output the correct sample names
process samtools_addreplacerg
 {
  input:
    tuple val(meta), path(cram)
  output:
    tuple val(meta), path(cramOut), path(cramIndex)
  shell:    
    reference = params[meta.sample.assembly].reference.fasta
    bed = "${meta.sample.individual_id}_${meta.chunk.index}.bed"
    bedContent = meta.chunk.regions.collect { region -> "${region.chrom}\t${region.chromStart}\t${region.chromEnd}" }.join("\n")

    cramOut="rg_added_${cram}"
    cramIndex=cram.name.endsWith('.cram') ? "rg_added_${cram}.crai" : "rg_added_${cram}.bai"

    template 'samtools_addreplacerg.sh'
}
