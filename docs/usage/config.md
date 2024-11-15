# Config
The VIP configuration is stored in [Nextflow configuration](https://www.nextflow.io/docs/latest/config.html) files.
An additional configuration file can be supplied on the command-line to overwrite default parameter values, add/update profiles, configure processes and update environment variables. 

## Parameters

| key                           | default     | description                                                                                                                       |
|-------------------------------|-------------|-----------------------------------------------------------------------------------------------------------------------------------|
| assembly                      | GRCh38      | output assembly, allowed values: [GRCh38]                                                                                         |
| GRCh37.reference.chain.GRCh38 | *installed* | chain file to convert GRCh37 to GRCh38 data                                                                                       |
| GRCh37.reference.fasta        | *installed* |                                                                                                                                   |
| GRCh37.reference.fastaFai     | *installed* |                                                                                                                                   |
| GRCh37.reference.fastaGzi     | *installed* |                                                                                                                                   |
| GRCh38.reference.fasta        | *installed* | GCA_000001405.15_GRCh38_no_alt_analysis_set                                                                                       |
| GRCh38.reference.fastaFai     | *installed* |                                                                                                                                   |
| GRCh38.reference.fastaGzi     | *installed* |                                                                                                                                   |
| T2T.reference.chain.GRCh38    | *installed* | chain file to convert T2T to GRCh38 data                                                                                          |
| T2T.reference.fasta           |             |                                                                                                                                   |
| T2T.reference.fastaFai        |             |                                                                                                                                   |
| T2T.reference.fastaGzi        |             |                                                                                                                                   |
| pcr_performed                 | false       | Indication if PCR was performed to get the data, if so certain tools will be disabled due to not being compatible with this data. |

**Warning:**
Please take note of the fact that for a different reference fasta.gz the  unzipped referenfasta file is also required. Both the zipped and unzipped fasta should have an index.

### FASTQ
| key                       | default     | description                                                                                            |
|---------------------------|-------------|--------------------------------------------------------------------------------------------------------|
| GRCh38.reference.fastaMmi | *installed* | for details, see [here](https://github.com/lh3/minimap2)                                               |
| fastp.options             |             | for details, see [here](https://github.com/OpenGene/fastp)                                             |
| minimap2.soft_clipping    | true        | In SAM output, use soft clipping for supplementary alignments (required when STR calling with Straglr) |
| minimap2.nanopore_preset  | lr:hq       | Preset to use for aligning Nanopore data, options: 'lr:hq' 'map-ont'.                                  |

### CRAM
| key                                            | default        | description                                                                                                                                                                          |
|------------------------------------------------|----------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| cnv.spectre.GRCh38.blacklist                   | *installed*    | blacklist in bed format for sites that will be ignored                                                                                                                               |
| cnv.spectre.GRCh38.metadata                    | *installed*    | metadata file for Ns removal, update this file only when using a different GRCh38 version than the one provided by VIP.                                                              |
| cram.call_snv                                  | true           | enable/disable the detection of short variants                                                                                                                                       |
| cram.call_str                                  | true           | enable/disable the detection of short tandem repeats                                                                                                                                 |
| cram.call_sv                                   | true           | enable/disable the detection of structural variants. disable this manually in case of non-paired-end Illumina data.                                                                  |
| snv.deeptrio.illumina.WES.model_name           | WES            | for details, see [here](https://github.com/google/deepvariant)                                                                                                                       |
| snv.deeptrio.illumina.WGS.model_name           | WGS            | for details, see [here](https://github.com/google/deepvariant)                                                                                                                       |
| snv.deeptrio.nanopore.model_name               | ONT            | for details, see [here](https://github.com/google/deepvariant)                                                                                                                       |
| snv.deeptrio.pacbio_hifi.model_name            | PACBIO         | for details, see [here](https://github.com/google/deepvariant)                                                                                                                       |
| snv.deepvariant.illumina.WES.model_name        | WES            | for details, see [here](https://github.com/google/deepvariant)                                                                                                                       |
| snv.deepvariant.illumina.WGS.model_name        | WGS            | for details, see [here](https://github.com/google/deepvariant)                                                                                                                       |
| snv.deepvariant.nanopore.model_name            | ONT_R104       | for details, see [here](https://github.com/google/deepvariant)                                                                                                                       |
| snv.deepvariant.pacbio_hifi.model_name         | PACBIO         | for details, see [here](https://github.com/google/deepvariant)                                                                                                                       |
| snv.glnexus.WES.preset                         | DeepVariantWES | for details, see [here](https://github.com/dnanexus-rnd/GLnexus/). allowed values: [DeepVariant, DeepVariantWES, DeepVariantWES_MED_DP, DeepVariant_unfiltered]                      |
| snv.glnexus.WGS.preset                         | DeepVariantWGS | for details, see [here](https://github.com/dnanexus-rnd/GLnexus/). allowed values: [DeepVariant, DeepVariantWGS, DeepVariant_unfiltered]                                             |
| str.expansionhunter.aligner                    | dag-aligner    | for details, see [here](https://github.com/Illumina/ExpansionHunter/blob/v5.0.0/docs/03_Usage.md). allowed values: [dag-aligner, path-aligner]                                       |
| str.expansionhunter.analysis_mode              | streaming      | for details, see [here](https://github.com/Illumina/ExpansionHunter/blob/v5.0.0/docs/03_Usage.md). allowed values: [seeking , streaming]                                             |
| str.expansionhunter.log_level                  | warn           | for details, see [here](https://github.com/Illumina/ExpansionHunter/blob/v5.0.0/docs/03_Usage.md). allowed values: [trace, debug, info, warn, or error]                              |
| str.expansionhunter.region_extension_length    | 1000           | for details, see [here](https://github.com/Illumina/ExpansionHunter/blob/v5.0.0/docs/03_Usage.md)                                                                                    |
| str.expansionhunter.GRCh38.variant_catalog     | *installed*    | for details, see [here](https://github.com/Illumina/ExpansionHunter/blob/v5.0.0/docs/03_Usage.md)                                                                                    |
| str.straglr.min_support                        | 2              | minimum number of support reads for an expansion to be captured in genome-scan, see [here](https://github.com/philres/straglr)                                                       |
| str.straglr.min_cluster_size                   | 2              | minimum number of reads required to constitute a cluster (allele) in GMM clustering, see [here](https://github.com/philres/straglr)                                                  |
| str.straglr.GRCh38.loci                        | *installed*    | from [here](https://github.com/epi2me-labs/wf-human-variation/blob/master/data/wf_str_repeats.bed)                                                                                   |
| sv.cutesv.batches                              | 10000000       | Batch of genome segmentation interval                                                                                                                                                |
| sv.cutesv.gt_round                             | 500            | Maximum round of iteration for alignments searching if perform genotyping                                                                                                            |
| sv.cutesv.include_bed                          |                | Only detect SVs in regions in the BED file                                                                                                                                           |
| sv.cutesv.ivcf                                 |                | Enable to perform force calling using the given vcf file                                                                                                                             |
| sv.cutesv.max_size                             | 100000         | Maximum size of SV to be reported. All SVs are reported when using -1                                                                                                                |
| sv.cutesv.max_split_parts                      | 7              | Maximum number of split segments a read may be aligned before it is ignored. All split segments are considered when using -1. (Recommand -1 when applying assembly-based alignment.) |
| sv.cutesv.merge_del_threshold                  | 0              | Maximum distance of deletion signals to be merged                                                                                                                                    |
| sv.cutesv.merge_ins_threshold                  | 100            | Maximum distance of insertion signals to be merged                                                                                                                                   |
| sv.cutesv.min_mapq                             | 20             | Minimum mapping quality value of alignment to be taken into account (recommend 10 for force calling)                                                                                 |
| sv.cutesv.min_read_len                         | 500            | Ignores reads that only report alignments with not longer than bp                                                                                                                    |
| sv.cutesv.min_siglength                        | 10             | Minimum length of SV signal to be extracted                                                                                                                                          |
| sv.cutesv.min_size                             | 30             | Minimum size of SV to be reported                                                                                                                                                    |
| sv.cutesv.min_support                          | 2              | Minimum number of reads that support a SV to be reported. Please note that the default is lower than the default of cuteSV itself to prevent missed SV calls. |
| sv.cutesv.read_range                           | 1000           | The interval range for counting reads distribution                                                                                                                                   |
| sv.cutesv.report_readid                        | false          | Enable to report supporting read ids for each SV                                                                                                                                     |
| sv.cutesv.retain_work_dir                      | false          | Enable to retain temporary folder and files                                                                                                                                          |
| sv.cutesv.write_old_sigs                       | false          | Enable to output temporary sig files                                                                                                                                                 |
| sv.cutesv.nanopore.diff_ratio_filtering_TRA    | 0.6            | Filter breakpoints with basepair identity less than <value> for translocation                                                                                                        |
| sv.cutesv.nanopore.diff_ratio_merging_DEL      | 0.3            | Do not merge breakpoints with basepair identity more than <value> for deletion                                                                                                       |
| sv.cutesv.nanopore.diff_ratio_merging_INS      | 0.3            | Do not merge breakpoints with basepair identity more than <value> for insertion                                                                                                      |
| sv.cutesv.nanopore.max_cluster_bias_DEL        | 100            | Maximum distance to cluster read together for deletion                                                                                                                               |
| sv.cutesv.nanopore.max_cluster_bias_DUP        | 500            | Maximum distance to cluster read together for duplication                                                                                                                            |
| sv.cutesv.nanopore.max_cluster_bias_INS        | 100            | Maximum distance to cluster read together for insertion                                                                                                                              |
| sv.cutesv.nanopore.max_cluster_bias_INV        | 500            | Maximum distance to cluster read together for inversion                                                                                                                              |
| sv.cutesv.nanopore.max_cluster_bias_TRA        | 50             | Maximum distance to cluster read together for translocation                                                                                                                          |
| sv.cutesv.nanopore.remain_reads_ratio          | 1.0            | The ratio of reads remained in cluster. Set lower when the alignment data have high quality but recommand over 0.5                                                                   |
| sv.cutesv.pacbio_hifi.diff_ratio_filtering_TRA | 0.6            | Filter breakpoints with basepair identity less than <value> for translocation                                                                                                        |
| sv.cutesv.pacbio_hifi.diff_ratio_merging_DEL   | 0.5            | Do not merge breakpoints with basepair identity more than <value> for deletion                                                                                                       |
| sv.cutesv.pacbio_hifi.diff_ratio_merging_INS   | 0.9            | Do not merge breakpoints with basepair identity more than <value> for insertion                                                                                                      |
| sv.cutesv.pacbio_hifi.max_cluster_bias_DEL     | 1000           | Maximum distance to cluster read together for deletion                                                                                                                               |
| sv.cutesv.pacbio_hifi.max_cluster_bias_DUP     | 500            | Maximum distance to cluster read together for duplication                                                                                                                            |
| sv.cutesv.pacbio_hifi.max_cluster_bias_INS     | 1000           | Maximum distance to cluster read together for insertion                                                                                                                              |
| sv.cutesv.pacbio_hifi.max_cluster_bias_INV     | 500            | Maximum distance to cluster read together for inversion                                                                                                                              |
| sv.cutesv.pacbio_hifi.max_cluster_bias_TRA     | 50             | Maximum distance to cluster read together for translocation                                                                                                                          |
| sv.cutesv.pacbio_hifi.remain_reads_ratio       | 1.0            | The ratio of reads remained in cluster. Set lower when the alignment data have high quality but recommand over 0.5                                                                   |

### gVCF
| key               | default     | description                                                                  |
|-------------------|-------------|------------------------------------------------------------------------------|
| gvcf.merge_preset | DeepVariant | allowed values: [gatk, gatk_unfiltered, DeepVariant, DeepVariant_unfiltered] |

### VCF
| key                                             | default     | description                                                                                                                                                                                                                                                 |
|-------------------------------------------------|-------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| vcf.start                                       |             | allowed values: [normalize, annotate, classify, filter, inheritance, classify_samples, filter_samples]. for reanalysis this defines from which step to start the workflow                                                                                   |
| vcf.annotate.annotsv_cache_dir                  | *installed* |                                                                                                                                                                                                                                                             |
| vcf.annotate.ensembl_gene_mapping               | *installed* |                                                                                                                                                                                                                                                             |
| vcf.annotate.vep_buffer_size                    | 1000        | for details, see [here](https://www.ensembl.org/info/docs/tools/vep/script/vep_options.html)                                                                                                                                                                |
| vcf.annotate.vep_cache_dir                      | *installed* |                                                                                                                                                                                                                                                             |
| vcf.annotate.vep_plugin_dir                     | *installed* |                                                                                                                                                                                                                                                             |
| vcf.annotate.vep_plugin_hpo                     | *installed* |                                                                                                                                                                                                                                                             |
| vcf.annotate.vep_plugin_inheritance             | *installed* |                                                                                                                                                                                                                                                             |
| vcf.annotate.vep_plugin_vkgl_mode               | 1           | allowed values: [0=full VKGL, 1=public VKGL]. update `vcf.annotate.GRCh38.vep_plugin_vkgl` accordingly                                                                                                                                                      |
| vcf.annotate.GRCh38.capice_model                | *installed* |                                                                                                                                                                                                                                                             |
| vcf.annotate.GRCh38.vep_custom_phylop           | *installed* |                                                                                                                                                                                                                                                             |
| vcf.annotate.GRCh38.vep_plugin_clinvar          | *installed* |                                                                                                                                                                                                                                                             |
| vcf.annotate.GRCh38.vep_plugin_gnomad           | *installed* |                                                                                                                                                                                                                                                             |
| vcf.annotate.GRCh38.vep_plugin_green_db_enabled | false       | enabling is only allowed for academic use, for details see [here](https://doi.org/10.5281/zenodo.5636209)                                                                                                                                                   |
| vcf.annotate.GRCh38.vep_plugin_green_db         | *installed* |                                                                                                                                                                                                                                                             |
| vcf.annotate.GRCh38.vep_plugin_spliceai_indel   | *installed* |                                                                                                                                                                                                                                                             |
| vcf.annotate.GRCh38.vep_plugin_spliceai_snv     | *installed* |                                                                                                                                                                                                                                                             |
| vcf.annotate.GRCh38.vep_plugin_utrannotator     | *installed* |                                                                                                                                                                                                                                                             |
| vcf.annotate.GRCh38.vep_plugin_vkgl             | *installed* | update `vcf.annotate.vep_plugin_vkgl_mode` accordingly                                                                                                                                                                                                      |
| vcf.classify.annotate_path                      | 1           | allowed values: [0=false, 1=true]. annotate variant-consequences with classification tree path                                                                                                                                                              |
| vcf.classify.GRCh38.decision_tree               | *installed* | for details, see [here](../advanced/classification_trees.md)                                                                                                                                                                                                |
| vcf.classify_samples.annotate_path              | 1           | allowed values: [0=false, 1=true]. annotate variant-consequences per sample with classification tree path                                                                                                                                                   |
| vcf.classify_samples.GRCh38.decision_tree       | *installed* | for details, see [here](../advanced/classification_trees.md)                                                                                                                                                                                                |
| vcf.filter.classes                              | VUS,LP,P    | for details, see [here](../advanced/classification_trees.md)                                                                                                                                                                                                |
| vcf.filter.consequences                         | true        | allowed values: [true, false]. true: filter individual consequences, false: keep all consequences for a variant if one consequence filter passes.                                                                                                           |
| vcf.filter_samples.classes                      | U1,U2       | for details, see [here](../advanced/classification_trees.md)                                                                                                                                                                                                |
| vcf.report.gado_genes                           | *installed* |                                                                                                                                                                                                                                                             |
| vcf.report.gado_hpo                             | *installed* |                                                                                                                                                                                                                                                             |
| vcf.report.gado_predict_info                    | *installed* |                                                                                                                                                                                                                                                             |
| vcf.report.gado_predict_matrix                  | *installed* |                                                                                                                                                                                                                                                             |
| vcf.report.include_crams                        | true        | allowed values: [true, false]. true: include cram files in the report for showing alignments in the genome browser, false: do not include the crams in the report, no aligments are shown in the genome browser. This will result in a smaller report size. |
| vcf.report.max_records                          |             |                                                                                                                                                                                                                                                             |
| vcf.report.max_samples                          |             |                                                                                                                                                                                                                                                             |
| vcf.report.template                             |             | for details, see [here](../advanced/report_templates.md)                                                                                                                                                                                                    |
| vcf.report.GRCh38.genes                         | *installed* |                                                                                                                                                                                                                                                             |

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
| process label           | configuration                                |
|-------------------------|----------------------------------------------|
| concat_vcf              | *default*                                    |
| cram_validate           | *default*                                    |
| cutesv_call             | cpus=4 memory='8GB' time='5h'                |
| deepvariant_call        | cpus=*default* memory='2GB * cpus' time='5h' |
| deepvariant_call_duo    | cpus=*default* memory='4GB * cpus' time='5h' |
| deepvariant_call_trio   | cpus=*default* memory='4GB * cpus' time='5h' |
| deepvariant_concat_gvcf | cpus=*default* memory='2GB' time='30m'       |
| deepvariant_concat_vcf  | cpus=*default* memory='2GB' time='30m'       |
| deepvariant_joint_call  | cpus=*default* memory='2GB' time='30m'       |
| expansionhunter_call    | cpus=4 memory='16GB' time='5h'               |
| manta_joint_call        | cpus=4 memory='8GB' time='5h'                |
| straglr_call            | *default*                                    |
| vcf_merge_str           | *default*                                    |
| vcf_merge_sv            | *default*                                    |

### gVCF
| process label | configuration             |
|---------------|---------------------------|
| gvcf_liftover | *default*                 |
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
| vcf_liftover                 | *default*                     |
| vcf_normalize                | *default*                     |
| vcf_report                   | memory = '4GB'                |
| vcf_slice                    | *default*                     |
| vcf_split                    | memory='100MB' time='30m'     |
| vcf_validate                 | memory='100MB' time='30m'     |

## Environment
See [https://github.com/molgenis/vip/tree/main/config](https://github.com/molgenis/vip/tree/main/config) for an overview of available environment variables.
Notably this allows to use different Apptainer containers for the tools that VIP relies on.
