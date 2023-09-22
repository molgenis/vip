# Config
The VIP configuration is stored in [Nextflow configuration](https://www.nextflow.io/docs/latest/config.html) files.
An additional configuration file can be supplied on the command-line to overwrite default parameter values, add/update profiles, configure processes and update environment variables. 

## Parameters

| key                       | default     | description                                 |
|---------------------------|-------------|---------------------------------------------|
| GRCh37.reference.fasta    | *installed* | human_g1k_v37                               |
| GRCh37.reference.fastaFai | *installed* |                                             |
| GRCh37.reference.fastaGzi | *installed* |                                             |
| GRCh38.reference.fasta    | *installed* | GCA_000001405.15_GRCh38_no_alt_analysis_set |
| GRCh38.reference.fastaFai | *installed* |                                             |
| GRCh38.reference.fastaGzi | *installed* |                                             |

**Warning:**
Please take note of the fact that for a different reference fasta.gz the  unzipped referenfasta file is also required. Both the zipped and unzipped fasta should have an index.

### FASTQ
| key                       | default     | description                                                                                            |
|---------------------------|-------------|--------------------------------------------------------------------------------------------------------|
| GRCh37.reference.fastaMmi | *installed* | for details, see [here](https://github.com/lh3/minimap2)                                               |
| GRCh38.reference.fastaMmi | *installed* | for details, see [here](https://github.com/lh3/minimap2)                                               |
| minimap2.soft_clipping    | true        | In SAM output, use soft clipping for supplementary alignments (required when STR calling with Straglr) |

### CRAM
| key                                         | default             | description                                                                                                                                             |
|---------------------------------------------|---------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------|
| cram.call_snv                               | true                | enable/disable the detection of short variants                                                                                                          |
| cram.call_str                               | true                | enable/disable the detection of short tandem repeats                                                                                                    |
| cram.call_sv                                | true                | enable/disable the detection of structural variants                                                                                                     |
| snv.illumina.tool                           | deepvariant         | use clair3 or deepvariant for snv calling                                                                                                               |
| snv.nanopore.tool                           | clair3              | use clair3 or deepvariant for snv calling                                                                                                               |
| snv.pacbio_hifi.tool                        | clair3              | use clair3 or deepvariant for snv calling                                                                                                               |
| snv.clair3.illumina.model_name              | ilmn                | for details, see [here](https://github.com/HKU-BAL/Clair3#pre-trained-models)                                                                           |
| snv.clair3.nanopore.model_name              | r941_prom_sup_g5014 | for details, see [here](https://github.com/HKU-BAL/Clair3#pre-trained-models)                                                                           |
| snv.clair3.pacbio_hifi.model_name           | hifi                | for details, see [here](https://github.com/HKU-BAL/Clair3#pre-trained-models)                                                                           |
| snv.deepvariant.illumina.WES.model_name     | WES                 | for details, see [here](https://github.com/google/deepvariant)                                                                                          |
| snv.deepvariant.nanopore.WGS.model_name     | WGS                 | for details, see [here](https://github.com/google/deepvariant)                                                                                          |
| snv.deepvariant.nanopore.model_name         | ONT_R104            | for details, see [here](https://github.com/google/deepvariant)                                                                                          |
| snv.deepvariant.pacbio_hifi.model_name      | PACBIO              | for details, see [here](https://github.com/google/deepvariant)                                                                                          |
| str.expansionhunter.aligner                 | dag-aligner         | for details, see [here](https://github.com/Illumina/ExpansionHunter/blob/v5.0.0/docs/03_Usage.md). allowed values: [dag-aligner, path-aligner]          |
| str.expansionhunter.analysis_mode           | streaming           | for details, see [here](https://github.com/Illumina/ExpansionHunter/blob/v5.0.0/docs/03_Usage.md). allowed values: [seeking , streaming]                |
| str.expansionhunter.log_level               | warn                | for details, see [here](https://github.com/Illumina/ExpansionHunter/blob/v5.0.0/docs/03_Usage.md). allowed values: [trace, debug, info, warn, or error] |
| str.expansionhunter.region_extension_length | 1000                | for details, see [here](https://github.com/Illumina/ExpansionHunter/blob/v5.0.0/docs/03_Usage.md)                                                       |
| str.expansionhunter.GRCh37.variant_catalog  | *installed*         | for details, see [here](https://github.com/Illumina/ExpansionHunter/blob/v5.0.0/docs/03_Usage.md)                                                       |
| str.expansionhunter.GRCh38.variant_catalog  | *installed*         | for details, see [here](https://github.com/Illumina/ExpansionHunter/blob/v5.0.0/docs/03_Usage.md)                                                       |
| str.straglr.min_support                     | 2                   | minimum number of support reads for an expansion to be captured in genome-scan, see [here](https://github.com/philres/straglr)                          |
| str.straglr.min_cluster_size                | 2                   | minimum number of reads required to constitute a cluster (allele) in GMM clustering, see [here](https://github.com/philres/straglr)                     |
| str.straglr.GRCh38.loci                     | *installed*         | from [here](https://github.com/epi2me-labs/wf-human-variation/blob/master/data/wf_str_repeats.bed)                                                      |

### gVCF
| key               | default         | description                                          |
|-------------------|-----------------|------------------------------------------------------|
| gvcf.merge_preset | gatk_unfiltered | allowed values: [gatk, gatk_unfiltered, DeepVariant] |

### VCF
| key                                           | default         | description                                                                                                                                                                                                                                                 |
|-----------------------------------------------|-----------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| vcf.start                                     |                 | allowed values: [normalize, annotate, classify, filter, inheritance, classify_samples, filter_samples]. for reanalysis this defines from which step to start the workflow                                                                                   |
| vcf.annotate.annotsv_cache_dir                | *installed*     |                                                                                                                                                                                                                                                             |
| vcf.annotate.ensembl_gene_mapping             | *installed*     |                                                                                                                                                                                                                                                             |
| vcf.annotate.vep_buffer_size                  | 1000            | for details, see [here](https://www.ensembl.org/info/docs/tools/vep/script/vep_options.html)                                                                                                                                                                |
| vcf.annotate.vep_cache_dir                    | *installed*     |                                                                                                                                                                                                                                                             |
| vcf.annotate.vep_plugin_dir                   | *installed*     |                                                                                                                                                                                                                                                             |
| vcf.annotate.vep_plugin_hpo                   | *installed*     |                                                                                                                                                                                                                                                             |
| vcf.annotate.vep_plugin_inheritance           | *installed*     |                                                                                                                                                                                                                                                             |
| vcf.annotate.vep_plugin_vkgl_mode             | 1               | allowed values: [0=full VKGL, 1=public VKGL]. update `vcf.annotate.GRCh38.vep_plugin_vkgl` accordingly                                                                                                                                                      |
| vcf.annotate.GRCh37.capice_model              | *installed*     |                                                                                                                                                                                                                                                             |
| vcf.annotate.GRCh37.vep_custom_phylop         | *installed*     |                                                                                                                                                                                                                                                             |
| vcf.annotate.GRCh37.vep_plugin_clinvar        | *installed*     |                                                                                                                                                                                                                                                             |
| vcf.annotate.GRCh37.vep_plugin_gnomad         | *installed*     |                                                                                                                                                                                                                                                             |
| vcf.annotate.GRCh37.vep_plugin_spliceai_indel | *installed*     |                                                                                                                                                                                                                                                             |
| vcf.annotate.GRCh37.vep_plugin_spliceai_snv   | *installed*     |                                                                                                                                                                                                                                                             |
| vcf.annotate.GRCh37.vep_plugin_utrannotator   | *installed*     |                                                                                                                                                                                                                                                             |
| vcf.annotate.GRCh37.vep_plugin_vkgl           | *installed*     |                                                                                                                                                                                                                                                             |
| vcf.annotate.GRCh38.capice_model              | *installed*     |                                                                                                                                                                                                                                                             |
| vcf.annotate.GRCh38.vep_custom_phylop         | *installed*     |                                                                                                                                                                                                                                                             |
| vcf.annotate.GRCh38.vep_plugin_clinvar        | *installed*     |                                                                                                                                                                                                                                                             |
| vcf.annotate.GRCh38.vep_plugin_gnomad         | *installed*     |                                                                                                                                                                                                                                                             |
| vcf.annotate.GRCh38.vep_plugin_spliceai_indel | *installed*     |                                                                                                                                                                                                                                                             |
| vcf.annotate.GRCh38.vep_plugin_spliceai_snv   | *installed*     |                                                                                                                                                                                                                                                             |
| vcf.annotate.GRCh38.vep_plugin_utrannotator   | *installed*     |                                                                                                                                                                                                                                                             |
| vcf.annotate.GRCh38.vep_plugin_vkgl           | *installed*     | update `vcf.annotate.vep_plugin_vkgl_mode` accordingly                                                                                                                                                                                                      |
| vcf.classify.annotate_labels                  | 0               | allowed values: [0=false, 1=true]. annotate variant-consequences with classification tree labels                                                                                                                                                            |
| vcf.classify.annotate_path                    | 1               | allowed values: [0=false, 1=true]. annotate variant-consequences with classification tree path                                                                                                                                                              |
| vcf.classify.GRCh37.decision_tree             | *installed*     | for details, see [here](../advanced/classification_trees.md)                                                                                                                                                                                                |
| vcf.classify.GRCh38.decision_tree             | *installed*     | for details, see [here](../advanced/classification_trees.md)                                                                                                                                                                                                |
| vcf.classify_samples.annotate_labels          | 0               | allowed values: [0=false, 1=true]. annotate variant-consequences per sample with classification tree labels                                                                                                                                                 |
| vcf.classify_samples.annotate_path            | 1               | allowed values: [0=false, 1=true]. annotate variant-consequences per sample with classification tree path                                                                                                                                                   |
| vcf.classify_samples.GRCh37.decision_tree     | *installed*     | for details, see [here](../advanced/classification_trees.md)                                                                                                                                                                                                |
| vcf.classify_samples.GRCh38.decision_tree     | *installed*     | for details, see [here](../advanced/classification_trees.md)                                                                                                                                                                                                |
| vcf.filter.classes                            | VUS,LP,P        | for details, see [here](../advanced/classification_trees.md)                                                                                                                                                                                                |
| vcf.filter.consequences                       | true            | allowed values: [true, false]. true: filter individual consequences, false: keep all consequences for a variant if one consequence filter passes.                                                                                                           |
| vcf.filter_samples.classes                    | MV,OK           | for details, see [here](../advanced/classification_trees.md)                                                                                                                                                                                                |
| vcf.report.gado_genes                         | *installed*     |                                                                                                                                                                                                                                                             |
| vcf.report.gado_hpo                           | *installed*     |                                                                                                                                                                                                                                                             |
| vcf.report.gado_predict_info                  | *installed*     |                                                                                                                                                                                                                                                             |
| vcf.report.gado_predict_matrix                | *installed*     |                                                                                                                                                                                                                                                             |
| vcf.report.include_crams                      | true            | allowed values: [true, false]. true: include cram files in the report for showing alignments in the genome browser, false: do not include the crams in the report, no aligments are shown in the genome browser. This will result in a smaller report size. |
| vcf.report.max_records                        |                 |                                                                                                                                                                                                                                                             |
| vcf.report.max_samples                        |                 |                                                                                                                                                                                                                                                             |
| vcf.report.template                           |                 | for details, see [here](../advanced/report_templates.md)                                                                                                                                                                                                    |
| vcf.report.GRCh37.genes                       | *installed*     |                                                                                                                                                                                                                                                             |
| vcf.report.GRCh38.genes                       | *installed*     |                                                                                                                                                                                                                                                             |

## Profiles
VIP pre-defines two profiles. The default profile is Slurm with fallback to local in case Slurm cannot be discovered.

| key   | description                                                                      |
|-------|----------------------------------------------------------------------------------|
| local | for details, see [here](https://www.nextflow.io/docs/latest/executor.html#local) |
| slurm | for details, see [here](https://www.nextflow.io/docs/latest/executor.html#slurm) |                                                        |

Additional profiles (for details, see [here](https://www.nextflow.io/docs/latest/config.html#config-profiles)) can be added to your configuration file and used on the command-line, for example to run VIP on the Amazon, Azure or Google Cloud.

## Process
By default, each process gets assigned `4 cpus`, `8GB of memory` and a `max runtime of 4 hours`. Depending on your system specifications and your analysis you might need to use updated values. For information on how to update process configuration see the [Nextflow documentation](https://www.nextflow.io/docs/latest/config.html#scope-process).
The following sections list all processes and their non-default configuration.

### FASTQ
| process label             | configuration                   |
|---------------------------|---------------------------------|
| concat_fastq              | *default*                       |
| concat_fastq_paired_end   | *default*                       |
| minimap2_align            | cpus=8 memory='16GB' time='23h' |
| minimap2_align_paired_end | cpus=8 memory='16GB' time='23h' |

### CRAM
| process label        | configuration                  |
|----------------------|--------------------------------|
| clair3_call          | cpus=4 memory='8GB' time='5h'  |
| clair3_joint_call    | cpus=4 memory='8GB' time='5h'  |
| concat_vcf           | *default*                      |
| cram_validate        | *default*                      |
| cutesv_call          | cpus=4 memory='8GB' time='5h'  |
| expansionhunter_call | cpus=4 memory='16GB' time='5h' |
| manta_call           | cpus=4 memory='8GB' time='5h'  |
| straglr_call         | *default*                      |
| vcf_merge_str        | *default*                      |
| vcf_merge_sv         | *default*                      |

### gVCF
| process label | configuration             |
|---------------|---------------------------|
| gvcf_validate | memory='100MB' time='30m' |
| gvcf_merge    | memory='2GB' time='30m'   |

### VCF
| process label                | configuration                 |
|------------------------------|-------------------------------|
| vcf_annotate                 | cpus=4 memory='8GB' time='4h' |
| vcf_annotate_publish         | *default*                     |
| vcf_classify                 | memory = '2GB'                |
| vcf_classify_publish         | *default*                     |
| vcf_classify_samples         | memory = '2GB'                |
| vcf_classify_samples_publish | *default*                     |
| vcf_concat                   | *default*                     |
| vcf_filter                   | *default*                     |
| vcf_filter_samples           | *default*                     |
| vcf_inheritance              | memory = '2GB'                |
| vcf_normalize                | *default*                     |
| vcf_report                   | memory = '4GB'                |
| vcf_slice                    | *default*                     |
| vcf_split                    | memory='100MB' time='30m'     |
| vcf_validate                 | memory='100MB' time='30m'     |

## Environment
See [https://github.com/molgenis/vip/tree/main/config](https://github.com/molgenis/vip/tree/main/config) for an overview of available environment variables.
Notably this allows to use different Apptainer containers for the tools that VIP relies on.
