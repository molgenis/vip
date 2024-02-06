#!/usr/bin/env python

"""
Script to convert single patient result to annotated BED like file.
Author: T Niemeijer
Date: 17-01-2024

positional CL arguments:
arg 1: input res path
arg 2: output bed path
"""

import sys
import pandas as pd

def expand_range(res, region_range=10):
    """
    add range nucleotides to start and stop. 
    subtracting one extra from start to convert 1 based to 0 based. 
    """
    res.start = res.start - (region_range + 1)
    res.end = res.end + (region_range)
    return res

def check_res_type(res):
    """
    Checks presence of type specific columns in dataframe.
    Will return the expected data type.
    """
    columns = res.columns
    if "deltaPsi" in columns:
        return "FRASER"
    elif "zScore" in columns:
        return "OUTRIDER"
    else: 
        return "MAE"



def format_res(res, pcutoff=0.5):
    """
    Formatting results from either FRASER, OUTRIDER or MAE
    -------------------------------------
    input:
        results file (.tsv)
        p_cutoff (float)
        mode (string)
    output:
        df with .bed like formatted data. (pd.Dataframe)
    """
    res = res.dropna() # drop NA's for now only support for known Entrez genes.
    res = res[res.chr != 'MT']
    res = res[res.padjust < pcutoff] 
    chrdict = {"1":1, "2":2, "3":3, "4":4, "5":5, "6":6, "7":7, "8":8,
            "9":9, "10":10, "11":11, "12":12, "13":13, "14":14,
            "15":15, "16":16, "17":17, "18":18, "19":19, "20":20,
            "21":21, "22":22, "X":23, "Y":24}
    res["chrindex"] = [chrdict[x] for x in res.chr]
    res = res.sort_values(["chrindex","start"])
    res = res.reset_index().drop(columns=["index","chrindex"])
    mode = check_res_type(res)
    match mode:
        case "FRASER":
            res = res[["chr","start","end","padjust", "deltaPsi"]]
            res = expand_range(res, 10)
        case "OUTRIDER":
            res = res[["chr","start", "end", "padjust", "zScore"]]
        case "MAE":
            res = res[["chr","start", "end", "padjust", "log2FC"]]
    return res

def main():
    args = sys.argv
    results = pd.read_csv(args[1], sep="\t")
    results = format_res(results)
    results.chr = [f'chr{ichr}' for ichr in results.chr] # for now, hardcoded conversion NCBI -> USCS chr format. Must be conditional.
    results.to_csv(path_or_buf=args[2], header=False, sep="\t", index=False)

if __name__ == "__main__":
    main()
