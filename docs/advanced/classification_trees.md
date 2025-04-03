# Classification trees

In order to end up with a small list of candidate variant records for interpretation VIP performs variant filtration by:

1. Classify all variant-consequences based on variant annotations
2. Remove variant-consequences based on their classes
3. Annotate remaining variant records using inheritance matcher
4. Classify all variant-consequences based on variant annotations in the context of samples
5. Remove variant-consequences based on their classes.
6. Remove variants that had all their variant-consequences removed

The following sections describe the default variant filtration strategies and how to customize classification and
filtration.

## Default

VIP contains default filtration strategies for variant-consequences as well as variant-consequences in the context of
samples.

### Variant-consequences

The default decision tree to classify variant-consequences works as follows:

1. Each variant-consequence is classified as `Benign`, `Likely Benign`, `VUS`, `Likely Pathogenic`, `Pathogenic` or
   `Remove`
2. Variant-consequences classified as `Benign`, `Likely Benign` and `Remove` are removed by default.

```mermaid
flowchart TD
filter_("Filter")
vkgl_("VKGL")
clinVar_("ClinVar")
chrom_("Chromosome")
gene_("Gene")
sv_("Is SV")
str_("Is STR")
str_status_("STR Status")
gnomAD_("GnomAD")
gnomAD_AF_("GnomAD AF")
annotSV_("AnnotSV")
spliceAI_("SpliceAI")
utr5_("5' UTR")
capice_("CAPICE")
exit_rm_("Remove")
style exit_rm_ fill:#00ff00
exit_b_("B")
style exit_b_ fill:#00ff00
exit_lb_("LB")
style exit_lb_ fill:#00ff00
exit_vus_("VUS")
style exit_vus_ fill:#00ff00
exit_lp_("LP")
style exit_lp_ fill:#00ff00
exit_p_("P")
style exit_p_ fill:#00ff00
capice_ -->|"true"| exit_lp_
gnomAD_ -->|"true"| sv_
clinVar_ -->|"default\nConflict\nVUS\nmissing"| chrom_
str_status_ -->|"full_mutation"| exit_lp_
capice_ -->|"false"| exit_lb_
annotSV_ -->|"1"| exit_b_
str_status_ -->|"default\npre_mutation"| exit_vus_
vkgl_ -->|"default\nVUS"| clinVar_
annotSV_ -->|"3"| exit_vus_
chrom_ -->|"false"| exit_rm_
str_ -->|"false\nmissing"| annotSV_
capice_ -->|"missing"| exit_vus_
gnomAD_ -->|"false"| gnomAD_AF_
vkgl_ -->|"LB"| exit_lb_
sv_ -->|"false"| spliceAI_
utr5_ -->|"true"| exit_vus_
annotSV_ -->|"5"| exit_p_
gene_ -->|"true"| gnomAD_
spliceAI_ -->|"default\nmissing"| utr5_
vkgl_ -->|"LP"| exit_lp_
vkgl_ -->|"P"| exit_p_
str_ -->|"true"| str_status_
chrom_ -->|"true\nmissing"| gene_
str_status_ -->|"normal"| exit_lb_
filter_ -->|"true\nmissing"| vkgl_
clinVar_ -->|"B/LB"| exit_lb_
annotSV_ -->|"4"| exit_lp_
clinVar_ -->|"LP/P"| exit_lp_
gene_ -->|"false"| exit_rm_
annotSV_ -->|"2"| exit_lb_
gnomAD_AF_ -->|"default\nmissing"| sv_
spliceAI_ -->|"Delta score (acceptor/donor gain/loss) > 0.42"| exit_lp_
utr5_ -->|"false"| capice_
gnomAD_AF_ -->|"Filtering allele Frequency (99% confidence) >= 0.02 or Number of Homozygotes > 5"| exit_lb_
annotSV_ -->|"default"| spliceAI_
vkgl_ -->|"B"| exit_b_
sv_ -->|"true"| str_
spliceAI_ -->|"Delta score (acceptor/donor gain/loss) > 0.13"| exit_vus_
filter_ -->|"false"| exit_rm_
```

*Above: default GRCh38 variant classification tree*

### Variant-consequences (samples)

The default decision tree to classify variant-consequences in the context of samples works as follows:

1. Each variant-consequence-sample is classified as `U1` (usable: probably), `U2` (usable: maybe), `U3` (usable:
   probably not) and `U4` (usable: only in cases of suspected incomplete penetrance).
2. Variant-consequences classified as `U3` and `U4` for all samples are removed by default.

```mermaid
flowchart TD
gt_("Genotype")
gq_("Genotype quality")
only_IP_("Only if AD IP")
vim_("Inheritance match")
vim_IP_("Inheritance match (IP)")
vid_("Inheritance denovo")
vid_IP_("Inheritance denovo (IP)")
exit_u1_("Usable: probably")
style exit_u1_ fill:#00ff00
exit_u2_("Usable: maybe")
style exit_u2_ fill:#00ff00
exit_u3_("Usable: probably not")
style exit_u3_ fill:#00ff00
exit_u4_("Usable: if IP")
style exit_u4_ fill:#00ff00
gq_ -->|"true\nmissing"| only_IP_
vid_ -->|"true"| exit_u1_
gq_ -->|"false"| exit_u3_
vid_IP_ -->|"missing"| exit_u2_
vid_IP_ -->|"true"| exit_u1_
vim_ -->|"missing"| exit_u2_
vim_ -->|"true"| exit_u1_
only_IP_ -->|"false\nmissing"| vim_
vim_ -->|"false"| vid_
vid_IP_ -->|"false"| vim_IP_
gt_ -->|"HOM_REF\nNO_CALL\nUNAVAILABLE"| exit_u3_
vim_IP_ -->|"false"| exit_u3_
vim_IP_ -->|"true\nmissing"| exit_u4_
only_IP_ -->|"true"| vid_IP_
vid_ -->|"false"| exit_u3_
gt_ -->|"default\nMIXED\nHET\nHOM_VAR"| gq_
vid_ -->|"missing"| exit_u2_

```

*Above: default variant sample classification tree*

## Customization and filtering

Please note that the classification tree only classifies variants, and filtering based on those classes is handled in
the next step of the pipeline.
The behaviour of the filtering is based on the classes specified in the configuration of the pipeline.

### Configuration

Detailed documentation on how to modify or create your own decision tree can be
found [here](https://github.com/molgenis/vip-decision-tree).

To use your modified or own decision tree the following parameter(s) should be updated (
see [here](../usage/config.md#parameters)).
For the difference between the two configuration items see the sections above and the decision tree
module [documentation](https://github.com/molgenis/vip-decision-tree).

- `vcf.classify.GRCh38.decision_tree`
- `vcf.classify_samples.GRCh38.decision_tree`

To customize the filtering of the variants based on the classification the following parameters can be updated (
see [here](../usage/config.md#parameters)).
These parameters should contain a comma separated list of classes (values of the LEAF nodes) of your decision tree you
would like to keep.

- `vcf.filter.classes`
- `vcf.filter_samples.classes`

The following repositories might be of interest when creating a new decision tree:

- [vip](https://github.com/molgenis/vip/tree/main/resources)
- [vip-decision-tree](https://github.com/molgenis/vip-decision-tree)