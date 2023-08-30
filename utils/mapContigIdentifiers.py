import csv
import gzip
import sys

if(len(sys.argv) != 4):
  print("Usage: python .\mapContigIdentifiers.py path/to/input/gff.gz path/to/assembly_report path/to/output/gff.gz")
  exit(1)

input_file_name = sys.argv[1]
mapping_file_name = sys.argv[2] #open(r'C:\Users\bartc\Desktop\GenesTest\GCF_000001405.39_GRCh38.p13_assembly_report.txt')
output_file_name = sys.argv[3]

mapping_file = open(mapping_file_name)
read_tsv = csv.reader(mapping_file, delimiter="\t")

mapping = {}
for row in read_tsv:
  if(not row[0].startswith('#')):
    mapping[row[6]] = row[9];
mapping_file.close

tsv_file = open(input_file_name)

with gzip.open(input_file_name, 'rt') as input:
  with gzip.open(output_file_name, 'wt') as output:
    for line in input:
      row = line.split("\t")
      if(not row[0].startswith('#')):
        row[0] = mapping[row[0]]
        output.write('\t'.join(row))

tsv_file.close()
output.close()