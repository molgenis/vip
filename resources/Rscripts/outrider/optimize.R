#' OUTRIDER optimize Q
#' Uses outrider rds object form create_outrider_dataset.R and performs q-optimization based on the max area under the precision-recall curve
#' 25-09-2023
#' Argument 1= input ods
#' Argument 2= output path Q eval


library(OUTRIDER)
library(dplyr)
library(tidyr)

args <- commandArgs(trailingOnly = TRUE)

# Open OUTRIDER dataset
ods <- readRDS(args[1])
q = as.numeric(gsub("\\[|\\]", "", args[2]))

# Find the encoding dimensions for the selected Q
ods <- findEncodingDim(ods, params=q, implementation='autoencoder')

# Get the encoding dimensions
encTable <- metadata(ods)[['encDimTable']]

q_out_name <- paste0(q,"_endim.tsv")

# Output encoding dim table
write.table(encTable, q_out_name, sep='\t',append = FALSE, row.names = FALSE, col.names = TRUE)