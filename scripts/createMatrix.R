#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)

sampleMatrixFile <- args[1]
sampleName <- args[2]
combinedMatrixFile <- args[3]

if (file.info(combinedMatrixFile)$size == 0) {
    combinedMatrix <- read.table(sampleMatrixFile, sep="\t", header=TRUE)
    colnames(combinedMatrix) <- c("Geneid", sampleName)
} else {
    sampleMatrix <- read.table(sampleMatrixFile, sep="\t", header=TRUE)
    combinedMatrix <- read.table(combinedMatrixFile, sep="\t", header=TRUE)
    colnames(sampleMatrix) <- c("Geneid", sampleName)
    combinedMatrix <- merge(combinedMatrix, sampleMatrix)
}

write.table(combinedMatrix, file = combinedMatrixFile, append = FALSE, quote = FALSE, sep = "\t",
            eol = "\n", na = "NA", dec = ".", row.names = FALSE,
            col.names = TRUE, qmethod = c("escape", "double"),
            fileEncoding = "")