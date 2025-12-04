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
is_mtdna_("is mtDNA")
mtdna_transcript_("mtDNA transcript")
mitotip_("MitoTIP")
apogee_("APOGEE")
hmtvar_("HmtVar")
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
filter_ -->|"true"| vkgl_
filter_ -->|"false"| exit_rm_
filter_ -->|"missing"| vkgl_
vkgl_ -->|"P"| exit_p_
vkgl_ -->|"default"| clinVar_
vkgl_ -->|"B"| exit_b_
vkgl_ -->|"LP"| exit_lp_
vkgl_ -->|"VUS"| clinVar_
vkgl_ -->|"LB"| exit_lb_
clinVar_ -->|"default"| chrom_
clinVar_ -->|"Conflict"| chrom_
clinVar_ -->|"VUS"| chrom_
clinVar_ -->|"LP/P"| exit_lp_
clinVar_ -->|"missing"| chrom_
clinVar_ -->|"B/LB"| exit_lb_
chrom_ -->|"true"| gene_
chrom_ -->|"false"| exit_rm_
chrom_ -->|"missing"| gene_
gene_ -->|"true"| is_mtdna_
gene_ -->|"false"| exit_rm_
sv_ -->|"true"| str_
sv_ -->|"false"| spliceAI_
str_ -->|"true"| str_status_
str_ -->|"false"| annotSV_
str_ -->|"missing"| annotSV_
str_status_ -->|"normal"| exit_lb_
str_status_ -->|"default"| exit_vus_
str_status_ -->|"pre_mutation"| exit_vus_
str_status_ -->|"full_mutation"| exit_lp_
is_mtdna_ -->|"true"| mtdna_transcript_
is_mtdna_ -->|"false"| gnomAD_
is_mtdna_ -->|"missing"| gnomAD_
mtdna_transcript_ -->|"default"| sv_
mtdna_transcript_ -->|"tRNA"| mitotip_
mtdna_transcript_ -->|"protein_coding"| apogee_
mitotip_ -->|"true"| hmtvar_
mitotip_ -->|"false"| exit_lb_
mitotip_ -->|"missing"| sv_
apogee_ -->|"true"| exit_lp_
apogee_ -->|"false"| exit_lb_
apogee_ -->|"missing"| sv_
hmtvar_ -->|"true"| exit_lp_
hmtvar_ -->|"false"| exit_lb_
hmtvar_ -->|"missing"| sv_
gnomAD_ -->|"true"| sv_
gnomAD_ -->|"false"| gnomAD_AF_
gnomAD_AF_ -->|"default"| sv_
gnomAD_AF_ -->|"missing"| sv_
gnomAD_AF_ -->|"Filtering allele Frequency (99% confidence) >= 0.02 or Number of Homozygotes > 5"| exit_lb_
annotSV_ -->|"1"| exit_b_
annotSV_ -->|"default"| spliceAI_
annotSV_ -->|"2"| exit_lb_
annotSV_ -->|"3"| exit_vus_
annotSV_ -->|"4"| exit_lp_
annotSV_ -->|"5"| exit_p_
spliceAI_ -->|"default"| utr5_
spliceAI_ -->|"Delta score (acceptor/donor gain/loss) > 0.13"| exit_vus_
spliceAI_ -->|"Delta score (acceptor/donor gain/loss) > 0.42"| exit_lp_
spliceAI_ -->|"missing"| utr5_
utr5_ -->|"true"| exit_vus_
utr5_ -->|"false"| capice_
capice_ -->|"true"| exit_lp_
capice_ -->|"false"| exit_lb_
capice_ -->|"missing"| exit_vus_
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
vig_("Inheritance match gene")
vim_("Inheritance match")
vig_IP_("Inheritance match gene (IP)")
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
gt_ -->|"default"| gq_
gt_ -->|"HOM_REF"| exit_u3_
gt_ -->|"NO_CALL"| exit_u3_
gt_ -->|"MIXED"| gq_
gt_ -->|"HET"| gq_
gt_ -->|"HOM_VAR"| gq_
gt_ -->|"UNAVAILABLE"| exit_u3_
gq_ -->|"true"| only_IP_
gq_ -->|"false"| exit_u3_
gq_ -->|"missing"| only_IP_
only_IP_ -->|"true"| vid_IP_
only_IP_ -->|"false"| vig_
only_IP_ -->|"missing"| vig_
vig_ -->|"true"| vim_
vig_ -->|"false"| vid_
vig_ -->|"missing"| vid_
vim_ -->|"true"| exit_u1_
vim_ -->|"false"| exit_u3_
vim_ -->|"missing"| exit_u2_
vig_IP_ -->|"true"| vim_IP_
vig_IP_ -->|"false"| exit_u3_
vig_IP_ -->|"missing"| exit_u3_
vim_IP_ -->|"true"| exit_u4_
vim_IP_ -->|"false"| exit_u3_
vim_IP_ -->|"missing"| exit_u4_
vid_ -->|"true"| exit_u1_
vid_ -->|"false"| exit_u3_
vid_ -->|"missing"| exit_u2_
vid_IP_ -->|"true"| exit_u1_
vid_IP_ -->|"false"| vig_IP_
vid_IP_ -->|"missing"| exit_u2_
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