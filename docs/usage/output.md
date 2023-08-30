# Output
[Click here for a live example](../vip_giab_hg001.html)

After VIP completes successfully the path specified by `--output` contains content similar to:
```bash
.nextflow
.nxf.home
.nxf.log
.nxf.tmp
.nxf.work
intermediates
nxf_report.html
nxf_timeline.html
my_project_id.html
my_project_id.vcf.gz
my_project_id.vcf.gz.csi
```

## Report
For each project defined in your ``--input`` sample-sheet a set of three files is created:
```bash
my_project.html
my_project.vcf.gz
my_project.vcf.gz.csi
```
In case no project identifiers were supplied these files will be called:
```bash
vip.html
vip.vcf.gz
vip.vcf.gz.csi
```

- `vip.html` is an interactive report based on `vip.vcf.gz` that can be viewed in any modern browser
- `vip.vcf.gz` contains annotated candidate variants for interpretation
- `vip.vcf.gz.csi` is the corresponding index file

By default, the report is a self-contained .html file that does not depend on external websites.
All data and code to interact with and display this data is contained in one file.
This ensures that no internet connection is required to view the report and enables easy sharing with other people.

- [Live example #0](../vip0.html)
- [Live example #0](../vip1.html)
- [Live example #0](../vip2.html)

![Example report](../img/report_example.png)

*Above: report example*

## Intermediates
VIP publishes selected intermediate results to allow [reanalysis](../examples/reanalysis.md) using the `vcf.start` [parameter](../usage/config.md).
Additionaly these results can be used to understand why variant records did not make it into the report. 

The content of the intermediates directory depends on the used ``--workflow`` and looks similar to: 
```bash
hlhs_famA_grch38_annotations.vcf.gz
hlhs_famA_grch38_annotations.vcf.gz.csi
hlhs_famA_grch38_classifications.vcf.gz
hlhs_famA_grch38_classifications.vcf.gz.csi
hlhs_famA_grch38_famA_sample0_small_variants.vcf.gz
hlhs_famA_grch38_famA_sample0_small_variants.vcf.gz.csi
hlhs_famA_grch38_famA_sample0_sv.vcf.gz
hlhs_famA_grch38_famA_sample0_sv.vcf.gz.csi
hlhs_famA_grch38_famA_sample1_small_variants.vcf.gz
hlhs_famA_grch38_famA_sample1_small_variants.vcf.gz.csi
hlhs_famA_grch38_famA_sample1_sv.vcf.gz
hlhs_famA_grch38_famA_sample1_sv.vcf.gz.csi
hlhs_famA_grch38_famA_sample2_small_variants.vcf.gz
hlhs_famA_grch38_famA_sample2_small_variants.vcf.gz.csi
hlhs_famA_grch38_famA_sample2_sv.vcf.gz
hlhs_famA_grch38_famA_sample2_sv.vcf.gz.csi
```

## Other
Besides the result files and intermediate files the following data is generated:
```bash
.nextflow
.nxf.home
.nxf.log
.nxf.tmp
.nxf.work
nxf_report.html
nxf_timeline.html
```
For details, see the [Nextflow documentation](https://www.nextflow.io/docs/latest/).