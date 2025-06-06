#' FRASER count new samples
#' Gagneur-lab FRASER (2.0)
#' Processes start from a samplesheet with SampleID's BAM paths featurecount settings etc. 
#' and creates fraser rds object and results .tsv
#' 28-10-2023
#' Argument 1= input path annot file
#' Argument 2= output path

library(FRASER)
library(dplyr)

args <- commandArgs(trailingOnly = TRUE)
register(MulticoreParam(workers=min(4, multicoreWorkers())))
workdir <- args[2]

# Load original sample table
args <- commandArgs(trailingOnly = TRUE)
settingsTable <- fread(args[1])
settingsTable$bamFile <- basename(settingsTable$bamFile)

fds <- FraserDataSet(colData=settingsTable, workingDir=workdir)
#strandSpecific(fds) <- as.integer(settingsTable$strandSpecific) #Added strand specificity
fds <- countRNAData(fds)
fds <- calculatePSIValues(fds)
fds <- saveFraserDataSet(fds)