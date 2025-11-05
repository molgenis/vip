#!/usr/bin/env Rscript

# Merges external_counts with counts from the provided bam files

args = commandArgs(trailingOnly=TRUE)

# Load arguments
sampleMatrixFiles <- args

count_matrices <- list()

for (file in sampleMatrixFiles) {
    count_matrices[[length(count_matrices) + 1]] <- read.table(file, header=TRUE, sep="\t")
}

ctsTable <- Reduce(function(x, y) merge(x, y, by.x='GeneID', by.y='GeneID', all.x=TRUE), count_matrices)

# Write counts to file.
write.table(ctsTable, file="merged_outrider_counts.txt", sep="\t" ,row.names=FALSE, col.names=TRUE)