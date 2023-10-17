#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)

# load packages
library(OUTRIDER)
library(dplyr)

# load arguments
countData <- args[1]
externalCountData <- args[2]
output <- args[3]

# Create data frames from count data
sampleData <- read.table(countData, sep="\t", header=TRUE)
externalCounts <- read.table(externalCountData, sep="\t", header=TRUE)

# Cut genes from external count data that are not present in samples
genesSample <- sampleData$geneID
externalCounts <- externalCounts[externalCounts$geneID %in% genesSample,]

# Order columns to prevent memory errors for larger datasets
sampleData <- sampleData[order(sampleData$geneID),]
externalCounts <- externalCounts[order(externalCounts$geneID),]

# Select x amount of external count samples
externalCounts <- externalCounts[, c(1:101)]

# Merge data
ctsTable <- merge(sampleData, externalCounts)

# Create Outrider DataSet matrix(ODS)
countDataMatrix <- as.matrix(ctsTable[ , -1])
rownames(countDataMatrix) <- ctsTable[ , 1]
ods <- OutriderDataSet(countData=countDataMatrix)

# Filter dataset
ods <- filterExpression(ods, minCounts=TRUE, filterGenes=TRUE)
ods <- ods[mcols(ods)$passedFilter,]

# Estimate size factors of dataset for q estimation
ods <- estimateSizeFactors(ods)

# Create sequence of values to be tested as optimal q values, range from minimum of 5
# to a maximum depended on datasize. Sequence size also based on datasize with a build
# in maximum to increase speed for large datasets.
a <- 5 
b <- min(ncol(ods), nrow(ods)) / 3
maxSteps <- 20
Nsteps <- min(maxSteps, b) 
pars_q <- round(exp(seq(log(a),log(b),length.out = Nsteps))) %>% unique

# Find optimal value for dimension reduction, q
ods <- findEncodingDim(ods, params=pars_q, implementation='autoencoder')
opt_q <- getBestQ(ods)

# Update for further implementation
ods <- estimateSizeFactors(ods)

# Run autoencoder
ods <- controlForConfounders(ods, q=opt_q, implementation="autoencoder", iterations=15)
ods <- fit(ods)

# Compute statistical values
ods <- computePvalues(ods, alternative="two.sided", method="BY")
ods <- computeZscores(ods)

saveRDS(ods, file = output)

# Create output
# res <- results(ods)
# write.table(res, output, row.names=FALSE, sep="\t")