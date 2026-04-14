# CRAM

The cram workflow can be run when starting with already aligned BAM/CRAM files.

## Samplesheet

```
family_id	proband	individual_id	hpo_ids	sequencing_platform	cram	sequencing_method	regions
fam0	true	NA12878	HP:0001626,HP:0000707	illumina	illumina_WES_GRCh38_chr20.cram	WES	single.bed
```

The required cram file can be downloaded from the [test resources](https://download.molgeniscloud.org/downloads/vip/test/resources/) folder.
The required bed and config files can be downloaded from [GitHub](https://github.com/molgenis/vip/tree/main/test/suites/cram/resources).

## Run the pipeline

```bash
vip.sh --workflow cram --input samplesheet.tsv --config single.cfg --output path/to/output/folder
```

## Output files

```
.
├── coverage
│   ├── vip_fam0_NA12878_mosdepth.global.dist.txt
│   ├── vip_fam0_NA12878_mosdepth.per-base.bed.gz
│   ├── vip_fam0_NA12878_mosdepth.per-base.bed.gz.csi
│   ├── vip_fam0_NA12878_mosdepth.region.dist.txt
│   ├── vip_fam0_NA12878_mosdepth.regions.bed.gz
│   ├── vip_fam0_NA12878_mosdepth.regions.bed.gz.csi
│   ├── vip_fam0_NA12878_mosdepth.summary.txt
│   ├── vip_fam0_NA12878_mosdepth.thresholds.bed.gz
│   └── vip_fam0_NA12878_mosdepth.thresholds.bed.gz.csi
├── intermediates
│   ├── NA12878_snv.g.vcf.gz
│   ├── NA12878_snv.g.vcf.gz.csi
│   ├── NA12878_snv.g.vcf.gz.stats
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
│   ├── vip_fam0_NA12878_str.vcf.gz
│   ├── vip_fam0_NA12878_str.vcf.gz.csi
│   ├── vip_fam0_NA12878_str.vcf.gz.stats
│   ├── vip_mtdnasnv.vcf.gz
│   ├── vip_mtdnasnv.vcf.gz.csi
│   ├── vip_mtdnasnv.vcf.gz.stats
│   ├── vip_sample_classifications.vcf.gz
│   ├── vip_sample_classifications.vcf.gz.csi
│   ├── vip_snv.vcf.gz
│   ├── vip_snv.vcf.gz.csi
│   ├── vip_snv.vcf.gz.stats
│   ├── vip_sv.vcf.gz
│   ├── vip_sv.vcf.gz.csi
│   └── vip_sv.vcf.gz.stats
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
