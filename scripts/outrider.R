#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)

library(OUTRIDER)

countData <- args[1]
externalCountData <- args[2]
output <- args[3]

sampleData <- read.table(countData, sep="\t", header=TRUE)
externalCounts <- read.table(externalCountData, sep="\t", header=TRUE)

genesSample <- sampleData$geneID
externalCounts <- externalCounts[externalCounts$geneID %in% genesSample,]
# sampleData <- sampleData[sampleData$geneID %in% externalCounts$geneID,]

sampleData <- sampleData[order(sampleData$geneID),]
externalCounts <- externalCounts[order(externalCounts$geneID),]

externalCounts <- externalCounts[, c(1:11)]

ctsTable <- merge(sampleData, externalCounts)

countDataMatrix <- as.matrix(ctsTable[ , -1])
rownames(countDataMatrix) <- ctsTable[ , 1]

ods <- OutriderDataSet(countData=countDataMatrix)
ods <- filterExpression(ods, minCounts=TRUE, filterGenes=TRUE)
write("filtering", file="log_out.txt", sep='\t')
ods <- ods[mcols(ods)$passedFilter,]
write("passed filter", file="log_out.txt", sep='\t', append=TRUE)
ods <- estimateSizeFactors(ods)
write("size factor", file="log_out.txt", sep='\t', append=TRUE)
ods <- findEncodingDim(ods)
write("encoding dim", file="log_out.txt", sep='\t', append=TRUE)
opt_q <- getBestQ(ods)
write("best_q", file="log_out.txt", sep='\t', append=TRUE)
ods <- controlForConfounders(ods, q=opt_q, iterations=10)
write("cofounders", file="log_out.txt", sep='\t', append=TRUE)
ods <- fit(ods)
write("fit", file="log_out.txt", sep='\t', append=TRUE)
ods <- computePvalues(ods, alternative="two.sided", method="BY")
write("pval", file="log_out.txt", sep='\t', append=TRUE)
ods <- computeZscores(ods)
write("zscore", file="log_out.txt", sep='\t', append=TRUE)
res <- results(ods)
write("res", file="log_out.txt", sep='\t', append=TRUE)
write.table(res, output, row.names=FALSE)