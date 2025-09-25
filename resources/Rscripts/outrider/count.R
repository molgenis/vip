#' featurecounts with strand specificity and combining
#' used in outrider_env
#' Argument 1= samplesheet path
#' Argument 2= annotation file path
#' Argument 3= output path

library(Rsubread)
library(dplyr)

args <- commandArgs(trailingOnly = TRUE)

# Arguments
sampleid <- args[1]
bamfile <- args[2]
gtf <- args[3]
paired_end <- args[4]
strand_specific <- args[5]

if (paired_end == "TRUE") {
    paired_end <- TRUE
} else {
    paired_end <- FALSE
}

print(strand_specific)

# Check for strand specificity and append different count matrices to count_matrices
fc <- featureCounts(bamfile, annot.ext=gtf, isGTFAnnotationFile=TRUE, nthreads=4, allowMultiOverlap=TRUE, isPairedEnd=paired_end, strandSpecific=strand_specific)

GeneID <- fc$annotation$GeneID 
ctsTable <- cbind(GeneID, fc$counts)
statsTable <- fc$stat

# Rename sample name (from bam) with the sampleid 
colnames(ctsTable)[colnames(ctsTable) == basename(bamfile)] <- sampleid

# Write counts to file.
write.table(ctsTable, file=paste(sampleid,"outrider_counts.tsv", sep='_'), sep="\t" ,row.names=FALSE, col.names=TRUE)

# Write count summary to file.
write.table(statsTable, file=paste(sampleid,"outrider_count_summary.tsv", sep='_'), sep="\t" ,row.names=FALSE, col.names=TRUE)