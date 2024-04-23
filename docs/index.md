# Variant Interpretation Pipeline (VIP)
VIP is a flexible human variant interpretation pipeline for rare disease using state-of-the-art pathogenicity prediction ([CAPICE](https://github.com/molgenis/capice)) and template-based interactive reporting to facilitate decision support.

The VIP pipeline can be used starting from either your `fastq`, `bam/cram` or `.g.vcf/vcf` data,
every entry point will result in a `vcf` file with your annotated, classified and filtered variants 
as well as a interactive HTML report with the same variants, prioritized by the CAPICE pathogenicity score 
and providing additional aids like a genome browser and a representation of the decisions leading to the VIP classification.
VIP can be used for single patients, families or cohort data.

!!! tip "Try it yourself"
    Visit <a href="https://vip.molgeniscloud.org/">https://vip.molgeniscloud.org/</a> to analyse your own variants 

!!! tip
    Preprint now available at <a href="https://doi.org/10.1101/2024.04.11.24305656">medRxiv</a>

[Click here for a live example](vip_giab_hg001.html)

![Example report](img/report_example.png)]

*Above: report example*

![Example report](img/report_example_variant.png)

*Above: report example: genome browser*