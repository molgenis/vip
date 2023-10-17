library(OUTRIDER)
library(dplyr)

ctsTable <- read.table(SJOGRENCOUNTS, sep="\t", header=TRUE)
extCounts <- read.table(EXTERNALCOUNTS, sep="\t", header=TRUE)

# Filter all genes not found in samples
colnames(ctsTable)[colnames(ctsTable)=="Geneid"] <- "geneID"

genesSample <- ctsTable$geneID
extCounts <- extCounts[extCounts$geneID %in% genesSample,]

# Order columns to prevent memory errors for larger datasets

ext_150 <- extCounts[, c(1:151)]

ctsTable <- merge(ctsTable, ext_150)

# Create outrider data set object
countDataMatrix <- as.matrix(ctsTable[ , -1])
rownames(countDataMatrix) <- ctsTable[ , 1]
ods <- OutriderDataSet(countData=countDataMatrix)

# Filter data
ods <- filterExpression(ods, minCounts=TRUE, filterGenes=TRUE)
ods <- ods[mcols(ods)$passedFilter,]

# Estimate size factors
ods <- estimateSizeFactors(ods)

# Create parameters for encoding dimensions optimalization
a <- 5 
b <- min(ncol(ods), nrow(ods)) / 3
maxSteps <- 20
Nsteps <- min(maxSteps, b) 
pars_q <- round(exp(seq(log(a),log(b),length.out = Nsteps))) %>% unique

# Find best value for q
ods <- findEncodingDim(ods, params=pars_q, implementation='autoencoder')
opt_q <- getBestQ(ods)

# Estimate size factors
ods <- estimateSizeFactors(ods)

# Control for cofounders and fit the data
ods <- controlForConfounders(ods, q=opt_q, implementation="autoencoder", iterations=15)
ods <- fit(ods)

# Compute statistical values for results
ods <- computePvalues(ods, alternative="two.sided", method="BY")
ods <- computeZscores(ods)

saveRDS(ods, file = "outrider_opt_q_fs.rds")