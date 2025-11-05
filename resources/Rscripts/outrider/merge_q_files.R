#!/usr/bin/env Rscript

args = commandArgs(trailingOnly=TRUE)

# Load arguments
qFiles <- args

q_matrices <- list()

for (file in qFiles) {
    q_matrices[[length(q_matrices) + 1]] <- read.table(file, header=TRUE, sep="\t")
}

qTable <- do.call("rbind", q_matrices)

# Write counts to file.
write.table(qTable, file="merged_q_files.tsv", sep="\t" ,row.names=FALSE, col.names=TRUE)