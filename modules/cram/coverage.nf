process coverage {
  label 'coverage'
  
  publishDir "$params.output/coverage", mode: 'link'

  input:
    tuple val(meta), path(cram), path(cramCrai), path(regions)
  
  output:
    tuple val(meta), path(mosdepth_global), path(mosdepth_region),path(mosdepth_summary), path(mosdepth_per_base_bed),path(mosdepth_per_base_bed_csi), path(mosdepth_regions_bed), path(mosdepth_regions_bed_csi), path(mosdepth_thresholds_bed), path(mosdepth_thresholds_bed_csi)
  
  shell:
    mosdepth_global = "${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_mosdepth.global.dist.txt"
    mosdepth_region = "${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_mosdepth.region.dist.txt"
    mosdepth_summary = "${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_mosdepth.summary.txt"
    mosdepth_per_base_bed = "${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_mosdepth.per-base.bed.gz"
    mosdepth_per_base_bed_csi = "${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_mosdepth.per-base.bed.gz.csi"
    mosdepth_regions_bed = "${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_mosdepth.regions.bed.gz"
    mosdepth_regions_bed_csi = "${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_mosdepth.regions.bed.gz.csi"
    mosdepth_thresholds_bed = "${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_mosdepth.thresholds.bed.gz"
    mosdepth_thresholds_bed_csi= "${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_mosdepth.thresholds.bed.gz.csi"

    paramReference = params[meta.project.assembly].reference.fasta

    template 'coverage.sh'
  
  stub:
    mosdepth_global = "${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_mosdepth.global.dist.txt"
    mosdepth_region = "${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_mosdepth.region.dist.txt"
    mosdepth_summary = "${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_mosdepth.summary.txt"
    mosdepth_per_base_bed = "${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_mosdepth.per-base.bed.gz"
    mosdepth_per_base_bed_csi = "${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_mosdepth.per-base.bed.gz.csi"
    mosdepth_regions_bed = "${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_mosdepth.regions.bed.gz"
    mosdepth_regions_bed_csi = "${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_mosdepth.regions.bed.gz.csi"
    mosdepth_thresholds_bed = "${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_mosdepth.thresholds.bed.gz"
    mosdepth_thresholds_bed_csi = "${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_mosdepth.thresholds.bed.gz.csi"

    """
      touch "${mosdepth_global}"
      touch "${mosdepth_region}"
      touch "${mosdepth_summary}"
      touch "${mosdepth_per_base_bed}"
      touch "${mosdepth_per_base_bed_csi}"
      touch "${mosdepth_regions_bed}"
      touch "${mosdepth_regions_bed_csi}"
      touch "${mosdepth_thresholds_bed}"
      touch "${mosdepth_thresholds_bed_csi}"
    """
}