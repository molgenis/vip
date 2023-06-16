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
| key                       | default     | description                                              |
|---------------------------|-------------|----------------------------------------------------------|
| GRCh37.reference.fastaMmi | *installed* | for details, see [here](https://github.com/lh3/minimap2) |
| GRCh38.reference.fastaMmi | *installed* | for details, see [here](https://github.com/lh3/minimap2) |

### CRAM
| key                                             | default             | description                                                                   |
|-------------------------------------------------|---------------------|-------------------------------------------------------------------------------|
| cram.clair3.illumina.model_name                 | ilmn                | for details, see [here](https://github.com/HKU-BAL/Clair3#pre-trained-models) |
| cram.clair3.nanopore.model_name                 | r941_prom_sup_g5014 | for details, see [here](https://github.com/HKU-BAL/Clair3#pre-trained-models) |
| cram.clair3.pacbio_hifi.model_name              | hifi                | for details, see [here](https://github.com/HKU-BAL/Clair3#pre-trained-models) |
| cram.sniffles2.GRCh37.tandem_repeat_annotations | *installed*         | for details, see [here](https://github.com/fritzsedlazeck/Sniffles)           |
| cram.sniffles2.GRCh38.tandem_repeat_annotations | *installed*         | for details, see [here](https://github.com/fritzsedlazeck/Sniffles)           |

### VCF
| key                                           | default         | description                                                                                                                                                               |
|-----------------------------------------------|-----------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| vcf.gvcf_merge_preset                         | gatk_unfiltered | allowed values: [gatk, gatk_unfiltered, deepvariant]                                                                                                                      |
| vcf.start                                     |                 | allowed values: [normalize, annotate, classify, filter, inheritance, classify_samples, filter_samples]. for reanalysis this defines from which step to start the workflow |
| vcf.annotate.annotsv_cache_dir                | *installed*     | 
| vcf.annotate.vep_buffer_size                  | 1000            | for details, see [here](https://www.ensembl.org/info/docs/tools/vep/script/vep_options.html)                                                                              |
| vcf.annotate.vep_cache_dir                    | *installed*     |                                                                                                                                                                           |
| vcf.annotate.vep_plugin_dir                   | *installed*     |                                                                                                                                                                           |
| vcf.annotate.vep_plugin_hpo                   | *installed*     |                                                                                                                                                                           |
| vcf.annotate.vep_plugin_inheritance           | *installed*     |                                                                                                                                                                           |
| vcf.annotate.vep_plugin_vkgl_mode             | 1               | allowed values: [0=full VKGL, 1=public VKGL]. update `vcf.annotate.GRCh38.vep_plugin_vkgl` accordingly                                                                    |
| vcf.annotate.GRCh37.capice_model              | *installed*     |                                                                                                                                                                           |
| vcf.annotate.GRCh37.vep_custom_gnomad         | *installed*     |                                                                                                                                                                           |
| vcf.annotate.GRCh37.vep_custom_clinvar        | *installed*     |                                                                                                                                                                           |
| vcf.annotate.GRCh37.vep_custom_phylop         | *installed*     |                                                                                                                                                                           |
| vcf.annotate.GRCh37.vep_plugin_spliceai_indel | *installed*     |                                                                                                                                                                           |
| vcf.annotate.GRCh37.vep_plugin_spliceai_snv   | *installed*     |                                                                                                                                                                           |
| vcf.annotate.GRCh37.vep_plugin_utrannotator   | *installed*     |                                                                                                                                                                           |
| vcf.annotate.GRCh37.vep_plugin_vkgl           | *installed*     |                                                                                                                                                                           |
| vcf.annotate.GRCh38.capice_model              | *installed*     |                                                                                                                                                                           |
| vcf.annotate.GRCh38.vep_custom_gnomad         | *installed*     |                                                                                                                                                                           |
| vcf.annotate.GRCh38.vep_custom_clinvar        | *installed*     |                                                                                                                                                                           |
| vcf.annotate.GRCh38.vep_custom_phylop         | *installed*     |                                                                                                                                                                           |
| vcf.annotate.GRCh38.vep_plugin_spliceai_indel | *installed*     |                                                                                                                                                                           |
| vcf.annotate.GRCh38.vep_plugin_spliceai_snv   | *installed*     |                                                                                                                                                                           |
| vcf.annotate.GRCh38.vep_plugin_utrannotator   | *installed*     |                                                                                                                                                                           |
| vcf.annotate.GRCh38.vep_plugin_vkgl           | *installed*     | update `vcf.annotate.vep_plugin_vkgl_mode` accordingly                                                                                                                    |
| vcf.classify.annotate_labels                  | 0               | allowed values: [0=false, 1=true]. annotate variant-consequences with classification tree labels                                                                          |
| vcf.classify.annotate_path                    | 1               | allowed values: [0=false, 1=true]. annotate variant-consequences with classification tree path                                                                            |   |
| vcf.classify.GRCh37.decision_tree             | *installed*     | for details, see [here](../advanced/classification_trees)                                                                                                                 |
| vcf.classify.GRCh38.decision_tree             | *installed*     | for details, see [here](../advanced/classification_trees)                                                                                                                 |
| vcf.classify_samples.annotate_labels          | 0               | allowed values: [0=false, 1=true]. annotate variant-consequences per sample with classification tree labels                                                               |
| vcf.classify_samples.annotate_path            | 1               | allowed values: [0=false, 1=true]. annotate variant-consequences per sample with classification tree path                                                                 |
| vcf.classify_samples.GRCh37.decision_tree     | *installed*     | for details, see [here](../advanced/classification_trees)                                                                                                                 |
| vcf.classify_samples.GRCh38.decision_tree     | *installed*     | for details, see [here](../advanced/classification_trees)                                                                                                                 |
| vcf.filter.classes                            | VUS,LP,P        | for details, see [here](../advanced/classification_trees)                                                                                                                 |
| vcf.filter.consequences                       | true            | allowed values: [true, false]                                                                                                                                             |
| vcf.filter_samples.classes                    | MV,OK           | for details, see [here](../advanced/classification_trees)                                                                                                                 |
| vcf.report.max_records                        |                 |                                                                                                                                                                           |
| vcf.report.max_samples                        |                 |                                                                                                                                                                           |
| vcf.report.template                           |                 | for details, see [here](../advanced/report_templates)                                                                                                                     |
| vcf.report.GRCh37.genes                       | *installed*     |                                                                                                                                                                           |
| vcf.report.GRCh38.genes                       | *installed*     |                                                                                                                                                                           |

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
| process                   | configuration                   |
|---------------------------|---------------------------------|
| concat_fastq              | *default*                       |
| concat_fastq_paired_end   | *default*                       |
| minimap2_align            | cpus=8 memory='16GB' time='23h' |
| minimap2_align_paired_end | cpus=8 memory='16GB' time='23h' |
| minimap2_index            | cpus=8 memory='16GB' time='23h' |

### CRAM
| process                | configuration                 |
|------------------------|-------------------------------|
| samtools_addreplacerg  | *default*                     |
| clair3_call            | cpus=4 memory='8GB' time='5h' |
| clair3_call_publish    | *default*                     |
| manta_call             | cpus=4 memory='8GB' time='5h' |
| manta_call_publish     | *default*                     |
| samtools_index         | *default*                     |
| sniffles2_call         | cpus=4 memory='8GB' time='5h' |
| sniffles2_combined_call| cpus=4 memory='8GB' time='5h' |
| sniffles2_call_publish | *default*                     |

### VCF
| process                  | configuration                 |
|--------------------------|-------------------------------|
| annotate                 | cpus=4 memory='8GB' time='4h' |
| annotate_publish         | *default*                     |
| classify                 | memory = '2GB'                |
| classify_publish         | *default*                     |
| classify_samples         | memory = '2GB'                |
| classify_samples_publish | *default*                     |
| concat                   | *default*                     |
| convert                  | *default*                     |
| filter                   | *default*                     |
| filter_samples           | *default*                     |
| index                    | memory='100MB' time='30m'     |
| inheritance              | memory = '2GB'                |
| merge_gvcf               | memory='2GB' time='30m'       |
| merge_vcf                | *default*                     |
| normalize                | *default*                     |
| report                   | memory = '4GB'                |
| slice                    | *default*                     |
| split                    | memory='100MB' time='30m'     |
| stats                    | *default*                     |

## Environment
See [https://github.com/molgenis/vip/tree/main/config](https://github.com/molgenis/vip/tree/main/config) for an overview of available environment variables.
Notably this allows to use different Apptainer containers for the tools that VIP relies on.
