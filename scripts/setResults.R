#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)

library(OUTRIDER)

# Loading in command line arguments
sample = args[1]
OutriderDataSet = args[2]
output = args[3]

# Load in the outrider dataset
ods <- readRDS(OutriderDataSet)

# Create results table
resultMatrix = results(ods)

# Take results corresponding to sample
sampleMatrix = resultMatrix[resultMatrix$sampleID == sample,]

# Load in gene name mapping file
genes <- read.table("/groups/umcg-gdio/tmp01/umcg-rheins-kars/vip/resources/gado/v1.0.3/genes.txt", header=FALSE)

# Function for correct ensembl IDs
get_gene <- function(gene) {
    return(strsplit(gene, '[.]')[[1]][[1]])
}

# Function to convert ensembl IDs to corresponding gene names if known
get_gene_name <- function(ensembl_id) {
    if(ensembl_id %in% genes$V1){
        return(genes[genes$V1==ensembl_id, 2])
    } else {
        return(ensembl_id)
    }
}

# Convert to gene names
sampleMatrix$geneNames <- sapply(sampleMatrix$geneID, get_gene)
sampleMatrix$geneNames <- sapply(sampleMatrix$geneNames, get_gene_name)

# Write output
write.table(sampleMatrix, output, row.names=FALSE, sep="\t")
