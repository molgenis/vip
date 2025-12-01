#!usr/bin/env python3
"""
Script to preprocess annotated variants tsv with provided column metadata .json
author: T. Niemeijer
date: 2025-09-05
"""

import gzip
import argparse
import json
import sys

### constants ###
STANDARD_HEADER = ["CHROM", "POS", "REF", "ALT","Feature_type","Feature"]
### --------- ###

def load_json_to_dict(path):
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

def get_args():
    """
    CL argument parser
    """
    parser = argparse.ArgumentParser(
                    prog='data_preprocess',
                    description='Preprocesses variants tsv based on metadata .json',
                    epilog='---------------------')
    parser.add_argument('-i','--input', type=str, required=True, help='path/to/input_variants_file.tsv')
    parser.add_argument('-o','--output', type=str, required=True, help='path/to/processed_variants_file.tsv.gz')
    parser.add_argument('-m','--metadata', type=str, required=True, help='path/to/column_metedata_file.json')

    return parser.parse_args()

def parse_line(line, sep='\t'):
    """Parse a line from the variants tsv"""
    return line.strip().split(sep)

def check_col_split(num, col, column_dict):
    """Function to check whether a column must be split and with what separator"""
    if col in column_dict:
        if "split" in column_dict[col] and column_dict[col]["split"] == "TRUE":
            if "separator" not in column_dict[col]:
                raise Exception(f"For column: {col}, no separator is specified in the metadata json")
            elif "fields" not in column_dict[col]:
                raise Exception(f"For column: {col}, no fields are specified in the metadata json")
            sep = column_dict[col]["separator"]
            return (num, col, True, sep)
    return (num, col, False, None)

def split_json_list(json_list_string):
    """Function to convert '[item1,item2,item3]' to Python list"""
    if json_list_string.startswith("[") and json_list_string.endswith("]"):
        return json_list_string[1:-1].split(',')
    else:
        return json_list_string.split(',')
    

def main():
    """
    main function
    """
    args = get_args()

    column_dict = load_json_to_dict(path=args.metadata)

    # Check whether the values should be kept and add these to a keep list.
    keep_columns = [index for index in column_dict if column_dict[index]["useParameter"] == "TRUE"]
    keep_columns.extend(STANDARD_HEADER) # Add the standard header values to the keep columns.
    with gzip.open(args.output, 'wt') as output_file, \
         open(args.input,'rt') as variants_file:

            header = parse_line(variants_file.readline())
            # Check if "ID" is in the header (for training data)
            if "ID" in header:
                keep_columns.append("ID")

            # (col_number:int, split:bool, sep:string)
            col_mapping = [check_col_split(n, col, column_dict) for n, col in enumerate(header) if col in keep_columns] 

            new_header = [col for n, col, spl, sep in  col_mapping if not spl] # Do not add the header that is going to be split. 

            # Extend new header with additional columns from the column metadata
            new_columns = [] #empty list in case there are no new columns
            for n, col, spl, sep in col_mapping:
                if spl:
                    new_columns.extend(split_json_list(column_dict[col]["fields"]))
                    
            new_header.extend(new_columns)
            output_file.write('\t'.join(new_header) + '\n')

            for line in variants_file:
                row = parse_line(line)
                if len(row) < len(header):
                    sys.stdout.write(f"Warning: Row has fewer columns than header: {line}\n")
                sys.stdout.flush()
                selected_values = [row[n] for n, col, spl, sep in col_mapping if not spl]
                split_rows = [(row[n], sep) for n, col, spl, sep in col_mapping if spl]


                split_values = [element for string, sep in split_rows for element in string.split(sep)]
                
                for column in new_columns:
                    if column in split_values:
                        selected_values.append("1")
                    else:
                        selected_values.append("0")

                output_file.write('\t'.join(selected_values) + '\n')



if __name__ == "__main__":
    main()

