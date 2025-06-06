#' OUTRIDER autoencoder find q
#' Last update: 20-01-2025
#' Script create ods objects
#' Argument 1= input path ods
#' Argument 2= qfile
#' Argument 3= samplesheet
#' Argument 4= output path ods
#' Argument 5= output path res
#' Argument 6= optional genome build (hg19 or hg38)


library(OUTRIDER)
library(dplyr)
library(tidyr)
library("AnnotationDbi")
library("org.Hs.eg.db")
library("data.table")
library(TxDb.Hsapiens.UCSC.hg19.knownGene)
library(TxDb.Hsapiens.UCSC.hg38.knownGene)


if(.Platform$OS.type == "unix") {
    register(MulticoreParam(workers=min(1, multicoreWorkers())))
} else {
    register(SnowParam(workers=min(1, multicoreWorkers())))
}


args <- commandArgs(trailingOnly = TRUE)

# Open OUTRIDER dataset
ods <- readRDS(args[1])
qtable <- read.table(args[2], header=TRUE, sep="\t")
samplesheet <- fread(args[3])


# Get the encodingDimension with the highest evaluation Loss
opt_q <- qtable$encodingDimension[which.max(qtable$evaluationLoss)]

print(paste0("Optimal q is: ",opt_q))

rds_out_path <- args[4]
res_out_path <- args[5]
genome_build <- args[6]

iter <- 15


ods <- controlForConfounders(ods, q=opt_q, iterations=iter)

ods <- computePvalues(ods, alternative="two.sided", method="BY")
ods <- computeZscores(ods)
res <- results(ods, all=TRUE)

# Output the outrider dataset file, and the results table. 
saveRDS(ods, file=rds_out_path)

# Filter data based on samples present in samplesheet
res <- res[res$sampleID %in% samplesheet$sampleID]

# Get genesymbols and reorder the dataframe
Ensembl_stripped <- unlist(lapply(strsplit(as.character(res$geneID), "[.]"), '[[', 1))

res$hgncSymbol = mapIds(org.Hs.eg.db,
                    keys=Ensembl_stripped, 
                    column="SYMBOL",
                    keytype="ENSEMBL",
                    multiVals="first")

res$entrezid = mapIds(org.Hs.eg.db,
                    keys=Ensembl_stripped, 
                    column="ENTREZID",
                    keytype="ENSEMBL",
                    multiVals="first")

names(res)[names(res) == 'geneID'] <- 'EnsemblID'

# Annotate chr start end.
if (genome_build == "hg19") {
    txdb <- TxDb.Hsapiens.UCSC.hg19.knownGene
} else {
    txdb <- TxDb.Hsapiens.UCSC.hg38.knownGene
}

res$chr = mapIds(txdb,
                    keys=res$entrezid, 
                    column="TXCHROM",
                    keytype="GENEID",
                    multiVals="first")

res$start = mapIds(txdb,
                    keys=res$entrezid, 
                    column="TXSTART",
                    keytype="GENEID",
                    multiVals="first")

res$end = mapIds(txdb,
                    keys=res$entrezid, 
                    column="TXEND",
                    keytype="GENEID",
                    multiVals="first")

# remove chr, to match the other results.
res$chr <- sub('^\\chr', '', res$chr)

# solve issue unimplemented type 'list' in 'EncodeElement'? https://stackoverflow.com/questions/24829027/unimplemented-type-list-when-trying-to-write-table
# as dataframe, because it complains about being an atomic vector??
res <- as.data.frame(apply(res,2,as.character))

write.table(res, paste("combined_samples", res_out_path, sep='_'), sep='\t', append = FALSE, row.names = FALSE, col.names = TRUE)

for (sampleid in unique(res$sampleID)){
    sample_out_path = paste(sampleid, res_out_path, sep='_')
    write.table(res[res$sampleID == sampleid,], sample_out_path, sep='\t', append = FALSE, row.names = FALSE, col.names = TRUE)
}