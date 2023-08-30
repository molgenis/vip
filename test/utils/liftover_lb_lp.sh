#!/bin/bash
#SBATCH --job-name=vip_test_liftover
#SBATCH --output=vip_test_liftover.out
#SBATCH --error=vip_test_liftover.err
#SBATCH --time=01:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=16gb
#SBATCH --nodes=1
#SBATCH --export=NONE
#SBATCH --get-user-env=L60
#SBATCH --tmp=4gb

if [ -z "$1" ]
then
      echo "usage: liftover_lb_lp.sh /absolute/path/to/vip/ specified_paths_for_apptainer_bind";
      exit 1;
fi

VIP_DIR=$1;
BIND=$2;

APPTAINER_BIND=${BIND} apptainer exec ${VIP_DIR}/images/bcftools-1.14.sif bcftools convert -O z -o ${VIP_DIR}/test/resources/lb.vcf.gz ${VIP_DIR}/test/resources/lb.bcf.gz

APPTAINER_BIND=${BIND} apptainer exec ${VIP_DIR}/images/picard-3.0.0.sif java -jar /opt/picard/lib/picard.jar LiftoverVcf -I "${VIP_DIR}/test/resources/lb.vcf.gz" -O "${VIP_DIR}/test/resources/lb_b38.vcf.gz" -C "${VIP_DIR}/test/resources/b37ToHg38.over.chain" --REJECT "${VIP_DIR}/test/resources/lb_b38_rejected.vcf.gz" -WMC "true" -R "${VIP_DIR}/resources/GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz"

APPTAINER_BIND=${BIND} apptainer exec ${VIP_DIR}/images/bcftools-1.14.sif bcftools convert -O b -o ${VIP_DIR}/test/resources/lb_b38.bcf.gz ${VIP_DIR}/test/resources/lb_b38.vcf.gz

APPTAINER_BIND=${BIND} apptainer exec ${VIP_DIR}/images/picard-3.0.0.sif java -jar /opt/picard/lib/picard.jar LiftoverVcf -I "${VIP_DIR}/test/resources/lp.vcf.gz" -O "${VIP_DIR}/test/resources/lp_b38.vcf.gz" -C "${VIP_DIR}/test/resources/b37ToHg38.over.chain" --REJECT "${VIP_DIR}/test/resources/lp_b38_rejected.vcf" -WMC "true" -R "${VIP_DIR}/resources/GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz"