 process outrider {
     input:
         tuple path(countMatrix), val(samples)
     output:
         path outrider.tsv
     scripts:
         """
         singularity exec --bind /groups/:/groups/ /groups/umcg-gdio/tmp01/umcg-rheins-kars/drop1.3.3/drop1.3.3.sif \
         Rscript /groups/umcg-gdio/tmp01/umcg-rheins-kars/outrider/outrider.R $countMatrix $samples outrider.tsv
         """
 }