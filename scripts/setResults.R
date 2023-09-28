#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)

# Loading in command line arguments
sample = args[1]
OutriderDataSet = args[2]
output = args[3]

# Load in the outrider dataset
resultMatrix = read.table(OutriderDataSet, sep="\t", header=TRUE)

# Take results corresponding to sample
sampleMatrix = resultMatrix[resultMatrix$sampleID == sample,]

# Change geneIDs

get_gene <- function(gene) {
    return(strsplit(gene, '[.]')[[1]][[1]])
}

get_gene_name <- function(ensembl_id) {
    if(ensembl_id %in% genes$V1){
        return(genes[genes$V1==ensembl_id, 2])
    } else {
        return(ensembl_id)
    }
}

sampleMatrix$geneID <- sapply(sampleMatrix$geneID, get_gene)
sampleMatrix$geneID <- sapply(sampleMatrix$geneID, get_gene_name)

# Write output
write.table(sampleMatrix, output, row.names=FALSE, sep="\t")
