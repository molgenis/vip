#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)

### Gets a count matrix from sample and adds it to a combined count matrix to be used in outrider

# Load arguments
sampleMatrixFile <- args[1]
sampleName <- args[2]
combinedMatrixFile <- args[3]

# Check if matrix file exists, if not, create it. If it does exist, add data of new sample.
if (file.info(combinedMatrixFile)$size == 0) {
    combinedMatrix <- read.table(sampleMatrixFile, sep="\t", header=TRUE)
    colnames(combinedMatrix) <- c("geneID", sampleName)
} else {
    sampleMatrix <- read.table(sampleMatrixFile, sep="\t", header=TRUE)
    combinedMatrix <- read.table(combinedMatrixFile, sep="\t", header=TRUE)
    colnames(sampleMatrix) <- c("geneID", sampleName)
    combinedMatrix <- merge(combinedMatrix, sampleMatrix)
}

# Write merged matrix to output file.
write.table(combinedMatrix, file = combinedMatrixFile, append = FALSE, quote = FALSE, sep = "\t",
            eol = "\n", na = "NA", dec = ".", row.names = FALSE,
            col.names = TRUE, qmethod = c("escape", "double"),
            fileEncoding = "")