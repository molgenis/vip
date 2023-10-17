library(OUTRIDER)
library(dplyr)

ctsTable <- read.table("/groups/umcg-gdio/tmp01/umcg-kmaassen/outrider-folder/counts_sjogren/sjogren_all_merged_featurecounts.Rmatrix.txt", sep="\t", header=TRUE)
extCounts <- read.table("/groups/umcg-gdio/tmp01/umcg-rheins-kars/vip/rna_resources/geneCounts.tsv", sep="\t", header=TRUE)

colnames(ctsTable)[colnames(ctsTable)=="Geneid"] <- "geneID"

genesSample <- ctsTable$geneID
extCounts <- extCounts[extCounts$geneID %in% genesSample,]

# Order columns to prevent memory errors for larger datasets

ext_150 <- extCounts[, c(1:151)]

ctsTable <- merge(ctsTable, ext_150)

countDataMatrix <- as.matrix(ctsTable[ , -1])
rownames(countDataMatrix) <- ctsTable[ , 1]
ods <- OutriderDataSet(countData=countDataMatrix)
ods <- filterExpression(ods, minCounts=TRUE, filterGenes=TRUE)
ods <- OUTRIDER(ods)

saveRDS(ods, file = "outrider_nonopt_q_fs.rds")