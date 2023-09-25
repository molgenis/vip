#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)

library('biomaRt')

# Loading in command line arguments
sample = "WB100017"
OutriderDataSet = args[2]
output = args[3]

# Load in the outrider dataset
resultMatrix = read.table(OutriderDataSet, sep="\t", header=TRUE)

# Take results corresponding to sample
sampleMatrix = resultMatrix[resultMatrix$sampleID = sample,]

# Change geneIDs


# Write output
write.table(sampleMatrix, output, row.names=FALSE)
