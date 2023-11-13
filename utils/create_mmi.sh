#!/bin/bash
#SBATCH --job-name=vip_mmi
#SBATCH --output=jobName.out
#SBATCH --error=jobName.err
#SBATCH --time=23:59:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=16gb
#SBATCH --nodes=1
#SBATCH --open-mode=append
#SBATCH --export=NONE
#SBATCH --get-user-env=L
set -euo pipefail

main() {
  local -r resourceDir="../vip/resources/GRCh38"
  cd "${resourceDir}"
  APPTAINER_BIND=/groups apptainer exec "../vip/images/minimap2-2.26.sif" minimap2 -t 8 -d GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz.mmi GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz
}

main "${@}"