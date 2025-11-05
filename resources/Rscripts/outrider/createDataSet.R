#' OUTRIDER create ods
#' Script creates ods objects and a list of Q's for optimization.
#' 07-05-2024
#' Argument 1= input path counts file
#' Argument 2= samplesheet
#' Argument 3= external count path
#' Argument 4= amount ext. counts

library(OUTRIDER)
library(dplyr)
library(tidyr)

#Initialize multithread options.
if(.Platform$OS.type == "unix") {
    register(MulticoreParam(workers=min(1, multicoreWorkers())))
} else {
    register(SnowParam(workers=min(1, multicoreWorkers())))
}

RANDOMEXT <- FALSE # experimental, add to config later

#randomized sample selection
random_extcounts <- function(external_count_amount, ext_counts){
    # Function to randomly select specific counts. Adjusted for Outrider.
    # - - - - - - - - - - - - - - - - - - - - - - 
    # input: The required amount of randomly selected samples
    # output: sorted list with random numbers is range of the ext counts

    indices <- 2:ncol(ext_counts)
    shuffled_indices <- sample(indices)
    
    return(shuffled_indices[1:external_count_amount])
}


args <- commandArgs(trailingOnly = TRUE)
ctsTable <- read.table(args[1], header=TRUE, sep="\t")
samplesheet <- read.table(args[2], header=TRUE, sep="\t")
iter <- 15


# Add external Counts / refactor to mandatory amount of ext counts?
if (length(args) >= 3){
    # By default add 100 external counts otherwise
    extctspath <- file.path(args[3])
    if (length(args) >= 4){
        ext_amount <- as.numeric(args[4])
    } else {
        ext_amount <- 100
    }
if (ext_amount > 0 ){
    extctsTable <- read.table(gzfile(extctspath), header=TRUE, sep="\t")
        if (RANDOMEXT){
        extctsTable <- extctsTable[,c(1,random_extcounts(ext_amount, extctsTable))] # always include the first index
    } else {
        extctsTable <- extctsTable[,c(1,2:ext_amount + 1)] # +1 always include the first index
    }
    count_data <- merge(x=ctsTable, y=extctsTable, by=c("GeneID"), all=TRUE)
} else {
        count_data <- ctsTable
    }
} else {
    count_data <- ctsTable
}

count_data[is.na(count_data)] <- 0
countDataMatrix <- as.matrix(count_data[ , -1])
rownames(countDataMatrix) <- count_data[ , 1]


ods <- OutriderDataSet(countData=countDataMatrix)
ods <- filterExpression(ods, gtfFile="/groups/umcg-gcc/tmp02/users/umcg-kmaassen/resources/gencode.v29.annotation.gtf", percentile=0.95, minCounts=FALSE, filterGenes=TRUE)
ods <- estimateSizeFactors(ods)

# Check if samples need to be excluded from a fit.
if ("excludeFit" %in% samplesheet) {
    samples_fit_exclusion <- samplesheet[samplesheet$excludeFit == TRUE]
    sampleExclusionMask(ods[,samples_fit_exclusion$sampleID]) <- TRUE
}

# Find q range
a <- 5 
b <- min(ncol(ods), nrow(ods)) / 3
maxSteps <- 20
Nsteps <- min(maxSteps, b) 
pars_q <- round(exp(seq(log(a),log(b),length.out = Nsteps))) %>% unique

qValues <- pars_q

# Output ODS and Q list
write.table(data.frame(qValues), file="q_values.txt", sep="\t" ,row.names=FALSE, col.names=FALSE)
saveRDS(ods, file="outrider.rds")