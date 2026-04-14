# FastQ

The fastq workflow can be run when starting with fastq files.

## The samplesheet

```
individual_id	sequencing_platform	fastq	regions
HG002	nanopore	m54238_180628_014238_s0_10000.Q20.part_001.fastq.gz,m54238_180628_014238_s0_10000.Q20.part_002.fastq.gz	nanopore.bed
```

The required fastq file can be downloaded from the [test resources](https://download.molgeniscloud.org/downloads/vip/test/resources/) folder.
The required bed and config files can be downloaded from [GitHub](https://github.com/molgenis/vip/tree/main/test/suites/fastq/resources).

## Run the pipeline

```bash
vip.sh --workflow fastq --input samplesheet.tsv --config nanopore.cfg --output path/to/output/folder
```

## Output files

```
.
├── coverage
│   ├── vip_fam0_HG002_mosdepth.global.dist.txt
│   ├── vip_fam0_HG002_mosdepth.region.dist.txt
│   ├── vip_fam0_HG002_mosdepth.regions.bed.gz
│   ├── vip_fam0_HG002_mosdepth.regions.bed.gz.csi
│   ├── vip_fam0_HG002_mosdepth.summary.txt
│   ├── vip_fam0_HG002_mosdepth.thresholds.bed.gz
│   └── vip_fam0_HG002_mosdepth.thresholds.bed.gz.csi
├── fastp
│   ├── vip_fam0_HG002_report.html
│   └── vip_fam0_HG002_report.json
├── intermediates
│   ├── HG002_snv.g.vcf.gz
│   ├── HG002_snv.g.vcf.gz.csi
│   ├── HG002_snv.g.vcf.gz.stats
│   ├── vip_annotations.vcf.gz
│   ├── vip_annotations.vcf.gz.csi
│   ├── vip_classifications.vcf.gz
│   ├── vip_classifications.vcf.gz.csi
│   ├── vip_combined.vcf.gz
│   ├── vip_combined.vcf.gz.csi
│   ├── vip_combined.vcf.gz.stats
│   ├── vip_complete_snv.vcf.gz
│   ├── vip_complete_snv.vcf.gz.csi
│   ├── vip_complete_snv.vcf.gz.stats
│   ├── vip.db
│   ├── vip_fam0_HG002_cnv.vcf.gz
│   ├── vip_fam0_HG002_cnv.vcf.gz.csi
│   ├── vip_fam0_HG002_cnv.vcf.gz.stats
│   ├── vip_fam0_HG002.cram
│   ├── vip_fam0_HG002.cram.crai
│   ├── vip_fam0_HG002.cram.stats
│   ├── vip_fam0_HG002_str.tsv
│   ├── vip_fam0_HG002_str.vcf.gz
│   ├── vip_fam0_HG002_str.vcf.gz.csi
│   ├── vip_fam0_HG002_str.vcf.gz.stats
│   ├── vip_fam0_HG002_sv.vcf.gz
│   ├── vip_fam0_HG002_sv.vcf.gz.csi
│   ├── vip_fam0_HG002_sv.vcf.gz.stats
│   ├── vip_mtdnasnv.vcf.gz
│   ├── vip_mtdnasnv.vcf.gz.csi
│   ├── vip_mtdnasnv.vcf.gz.stats
│   ├── vip_sample_classifications.vcf.gz
│   ├── vip_sample_classifications.vcf.gz.csi
│   ├── vip_snv.vcf.gz
│   ├── vip_snv.vcf.gz.csi
│   └── vip_snv.vcf.gz.stats
├── log
│   ├── nxf.log
│   ├── nxf_report.html
│   ├── nxf_timeline.html
│   ├── slurm_job.err
│   └── slurm_job.out
├── samplesheet.tsv
├── tmp
│   ├── nextflow
│   ├── nxf.temp
│   └── nxf.work
├── vip.html
├── vip.vcf.gz
└── vip.vcf.gz.csi
```
