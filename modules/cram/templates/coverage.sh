#!/bin/bash
set -euo pipefail

mosdepth () {
    local args=()
    args+=("--threads"  "!{task.cpus}")
    args+=("--by" "!{regions}")
    args+=("--thresholds" "1,5,10,15,20,30,50,100")
    args+=("--fasta" "!{paramReference}")
    args+=("mosdepth")
    args+=("!{cram}")
    ${CMD_MOSDEPTH} "${args[@]}"

    mv "mosdepth.mosdepth.global.dist.txt" "!{mosdepth_global}"
    mv "mosdepth.mosdepth.region.dist.txt" "!{mosdepth_region}"
    mv "mosdepth.mosdepth.summary.txt" "!{mosdepth_summary}"
    mv "mosdepth.per-base.bed.gz" "!{mosdepth_per_base_bed}"
    mv "mosdepth.per-base.bed.gz.csi" "!{mosdepth_per_base_bed_csi}"
    mv "mosdepth.regions.bed.gz" "!{mosdepth_regions_bed}"
    mv "mosdepth.regions.bed.gz.csi" "!{mosdepth_regions_bed_csi}"
    mv "mosdepth.thresholds.bed.gz" "!{mosdepth_thresholds_bed}"
    mv "mosdepth.thresholds.bed.gz.csi" "!{mosdepth_thresholds_bed_csi}"
}

main() {
  mosdepth
}

main "$@"
