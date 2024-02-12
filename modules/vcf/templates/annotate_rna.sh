#!/bin/bash
set -euo pipefail

fraserbed="!{basename}_fraser.bed"
outriderbed="!{basename}_outrider.bed"
maebed="!{basename}_mae.bed"
rna_res_path="!{rna_res}"
fraser_res="${rna_res_path}/*fraser.tsv"
outrider_res="${rna_res_path}/*outrider.tsv"
mae_res="${rna_res_path}/*mae.tsv"
sampleid="!{sampleid}"

#Abs path to USCS liftOver tool and chain file
liftovertool="/groups/umcg-gdio/tmp01/umcg-tniemeijer/RNA_outlier_dectection_internship/liftover/liftOver"
chain_hg19_hg38="/groups/umcg-gdio/tmp01/umcg-tniemeijer/RNA_outlier_dectection_internship/liftover/chain_files/hg19ToHg38.over.chain.gz"

fraser_columns="CHROM,FROM,TO,FORMAT/FRASER_PVAL,FORMAT/FRASER_dPSI"
outrider_columns="CHROM,FROM,TO,FORMAT/OUTRIDER_PVAL,FORMAT/OUTRIDER_ZSCORE"
mae_columns="CHROM,FROM,TO,FORMAT/MAE_PVAL,FORMAT/MAE_LOG2FC"


### Python script in 'Python' env. 
eval "$(conda shell.bash hook)"
source /groups/umcg-gdio/tmp01/umcg-tniemeijer/envs/mamba-env/etc/profile.d/mamba.sh
mamba activate dashboard_env

python "!{res_to_bed}" $fraser_res $fraserbed
python "!{res_to_bed}" $outrider_res $outriderbed
python "!{res_to_bed}" $mae_res $maebed

mamba deactivate

ml BCFtools
ml BEDTools

# check if bed file is empty or not, otherwise skip step but create proper file
# sort bed files 
# lift hg19 > hg38
# annotate the vcf with the results bed.

if [ -s "!{vcf}" ];
then
    if [ -s $fraserbed ];
    then
        bedtools sort -i $fraserbed > "sorted_${fraserbed}"
        $liftovertool "sorted_${fraserbed}" $chain_hg19_hg38 "sorted_lifted_${fraserbed}" "unMapped_${fraserbed}"
        bcftools annotate -s $sampleid -a "sorted_lifted_${fraserbed}" -h "!{fraser_header}" -c $fraser_columns "!{vcf}" --output-type "z" -o "fraser_!{vcfOut}"
    else
        cp "!{vcf}" "fraser_!{vcfOut}"
    fi

    if [ -s $outriderbed ];
    then
        bedtools sort -i $outriderbed > "sorted_${outriderbed}"
        $liftovertool "sorted_${outriderbed}" $chain_hg19_hg38 "sorted_lifted_${outriderbed}" "unMapped_${outriderbed}"
        bcftools annotate -s $sampleid -a "sorted_lifted_${outriderbed}" -h "!{outrider_header}" -c $outrider_columns "fraser_!{vcfOut}" --output-type "z" -o "fraser_outrider_!{vcfOut}"
    else
        cp "fraser_!{vcfOut}" "fraser_outrider_!{vcfOut}"
    fi

    if [ -s $maebed ];
    then
        bedtools sort -i $maebed > "sorted_${maebed}"
        $liftovertool "sorted_${maebed}" $chain_hg19_hg38 "sorted_lifted_${maebed}" "unMapped_${maebed}"
        bcftools annotate -s $sampleid -a "sorted_lifted_${maebed}" -h "!{mae_header}" -c $mae_columns "fraser_outrider_!{vcfOut}" --output-type "z" -o "!{vcfOut}"
    else
        cp "fraser_outrider_!{vcfOut}" "!{vcfOut}"
    fi
else
    touch "!{vcfOut}"
fi
