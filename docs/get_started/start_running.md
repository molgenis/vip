# Start running
After installation, it is time for a quick test to verify that VIP works using some test data.

## Input
To run VIP you need to provide at least `workflow`, `input` and `output` arguments (described in detail [here](../usage/command-line-options.md)). The following example processes a collection of .vcf files. 
```bash
cd vip
vip --workflow vcf --input test/resources/multiproject.tsv --output output_multiproject 
```
## Output
Executing the above command displays progress until the pipeline completes. 
```
N E X T F L O W  ~  version 22.10.6
Launching `vip_vcf.nf` [disturbed_khorana] DSL2 - revision: 8f8c80809c
executor >  local (27)
[-        ] process > samtools_index           -
[71/4bb8b5] process > vcf:convert (2)          [100%] 5 of 5 ✔
[c7/1f8dc7] process > vcf:index (1)            [100%] 1 of 1 ✔
[ad/51639f] process > vcf:stats (1)            [100%] 2 of 2 ✔
[54/a6c17d] process > vcf:merge_vcf (1)        [100%] 1 of 1 ✔
[a5/790ba1] process > vcf:merge_gvcf (1)       [100%] 1 of 1 ✔
[-        ] process > vcf:split                -
[64/dafd8f] process > vcf:normalize (2)        [100%] 2 of 2 ✔
[c4/ed6e06] process > vcf:annotate (1)         [100%] 2 of 2 ✔
[43/c63075] process > vcf:classify (2)         [100%] 2 of 2 ✔
[66/3adcef] process > vcf:filter (2)           [100%] 2 of 2 ✔
[d1/1d89ee] process > vcf:inheritance (1)      [100%] 2 of 2 ✔
[d7/d717a0] process > vcf:classify_samples (1) [100%] 2 of 2 ✔
[45/0564f9] process > vcf:filter_samples (1)   [100%] 2 of 2 ✔
[-        ] process > vcf:concat               -
[-        ] process > vcf:slice                -
[ad/fc2b6c] process > vcf:report (2)           [100%] 3 of 3 ✔
Duration    : 1m 00s
CPU hours   : 0.2
Succeeded   : 27
```
## Results
```bash
ls -1 output_multiproject/
```
The output folder contains one report for each project described in [test/resources/multiproject.tsv](https://github.com/molgenis/vip/blob/main/test/resources/multiproject.tsv). 
```
intermediates
nxf_report.html
nxf_timeline.html
vip0.html
vip0.vcf.gz
vip0.vcf.gz.csi
vip1.html
vip1.vcf.gz
vip1.vcf.gz.csi
vip2.html
vip2.vcf.gz
vip2.vcf.gz.csi
```

The files `vip0.html`, `vip1.html` and `vip2.html` can be opened in your browser and display an interactive report based on the corresponding `.vcf.gz` output files.
The outputs are described in more detail [here](../usage/command-line-options.md).