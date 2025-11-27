#!usr/bin/env python3
"""
Script to predict with a XGB model on tabular data prob scores
author: T. Niemeijer
date: 2025-09-19
"""


import argparse
import itertools
import os
import sys
import json

import pandas as pd
import numpy as np  
import xgboost as xgb

### constants ###
DTYPE_DICT = {"STRING":'category', "FLOAT":float, "INT":int}
### --------- ###


def get_args() -> argparse.ArgumentParser:
    """
    CL argument parser
    """
    parser = argparse.ArgumentParser(
                    prog='data_preprocess',
                    description='Preprocesses variants tsv based on metadata .json',
                    epilog='---------------------')
    parser.add_argument('-i','--input', type=str, required=True, help='path/to/input_data.tsv.gz')
    parser.add_argument('-o','--output', type=str, required=True, help='path/to/classified_data.tsv.gz')
    parser.add_argument('-c','--classifier', type=str, required=True, help='path/to/trained_model.ubj')
    parser.add_argument('-m','--metadata', type=str, required=True, help='path/to/column_metedata_file.json')

    return parser.parse_args()

def load_json_to_dict(path: str) -> dict:
    """
    function to open the column metadata json and return a python dict type
    
    input:
        path - path to column metadata json; string
    
    output:
        metadata_dict - column metadata data python dict
    """
    with open(path, 'r') as metadata_file:
        metadata_dict = json.loads(metadata_file.read())

    return metadata_dict

def split_json_list(json_list_string: str) -> list:
    """Function to convert '[item1,item2,item3]' to Python list"""
    if json_list_string.startswith("[") and json_list_string.endswith("]"):
        return json_list_string[1:-1].split(',')
    else:
        return json_list_string.split(',')
    
def get_col_datatype(json_dict: dict) -> dict:
    """Function to get col datatypes from json"""
    #Add dtypes for unsplit cols
    columns_dtype_dict = {index:DTYPE_DICT[json_dict[index]["dataType"]] for index in json_dict if
                               (json_dict[index]["useParameter"] == "TRUE") and not (json_dict[index]["split"] == "TRUE") }
    #Add dtypes for split cols
    additional_cols = [split_json_list(json_dict[index]["fields"]) for index in json_dict if
                               (json_dict[index]["split"] == "TRUE") and (json_dict[index]["useParameter"] == "TRUE")]
    
    columns_dtype_dict.update({item:int for item in list(itertools.chain(*additional_cols))})
    return columns_dtype_dict

def load_model(model_path: os.PathLike) -> xgb.XGBClassifier:
    model = xgb.XGBClassifier()
    model.load_model(model_path)
    return model

def replace_missing(data, col_dtype_dict):
    """
    Replace missing values and change column data types in a pandas DataFrame.

    Parameters:
    - data (pd.DataFrame): Input DataFrame with potential missing values.
    - col_dtype_dict (dict): Dictionary mapping column names to desired data types.

    Returns:
    - pd.DataFrame: Updated DataFrame with missing values handled and column types changed.
    """
    for col, dtype in col_dtype_dict.items():
        if col in data.columns:
            # Replace missing values based on target dtype
            data[col] = data[col].replace('.', np.nan)
            if dtype == float:
                data[col] = data[col].fillna(np.nan)
            elif dtype == int:
                data[col] = data[col].fillna(0).astype(float).astype(int)  # Avoid errors from NaNs
            elif dtype == 'category':
                data[col] = data[col].fillna('')
            elif dtype == bool:
                data[col] = data[col].fillna(False)
            else:
                data[col] = data[col].fillna(np.nan)

            # Convert column to desired dtype
            try:
                data[col] = data[col].astype(dtype)
            except Exception as e:
                print(f"Could not convert column '{col}' to {dtype}: {e}")
    return data

def main() -> None:
    """"main predict script"""
    os.environ["OMP_THREAD_LIMIT"] = "1"
    args = get_args()
    col_dtype_dict = get_col_datatype(load_json_to_dict(args.metadata))
    sys.stdout.write(f"Making predictions using the following columns: {col_dtype_dict.keys()}\n")
    sys.stdout.flush()
    data = pd.read_table(args.input, sep='\t')
    data = replace_missing(data, col_dtype_dict)
    model = load_model(args.classifier)
    predicted = model.predict_proba(data[col_dtype_dict.keys()])[:, 1] # To get the probability of 
    data["score"] = predicted
    data.to_csv(args.output, sep="\t", index=False)

if __name__ == "__main__":
    main()