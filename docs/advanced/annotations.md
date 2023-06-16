# Annotations

## VEP
VIP uses the [Ensamble Effect Predictor](FIXME) to annotate all variants with their consequences. We use VEP with the `refseq` option for the transcripts, and with the flags for `sift` and `polyphen` annotations enabled.

### Plugins
Below we describe the other sources which we annotate using the VEP plugin framework.

#### CAPICE
[CAPICE](https://github.com/molgenis/capice) is a computational method for predicting the pathogenicity of SNVs and InDels. It is a gradient boosting tree model trained using a variety of genomic annotations used by CADD score and trained on the clinical significance. CAPICE performs consistently across diverse independent synthetic, and real clinical data sets. It ourperforms the current best method in pathogenicity estimation for variants of different molecular consequences and allele frequency.

We run the CAPICE application in the VIP pipeline and use a VEP plugin to annotate the VEP output with the scores from the CAPICE output file.

#### VKGL
The datashare workgroup of VKGL has set up a [central database](https://www.vkgl.nl/nl/diagnostiek/vkgl-datashare-database) to enable mutual sharing of variant classifications through a partly automatic process. An additional goal is the public sharing of these data. The currently publicly available part of the database consists of DNA variant classifications established based on (former) diagnostic questions.

We add the classifications from an export of the database and use a VEP plugin to annotate the VEP output with the classifications from the this file.

#### SpliceAI
SpliceAI is an open-source deep learning splicing prediction algorithm that has demonstrated in the past few years its high ability to predict splicing defects caused by DNA variations.

We add the scores from the available precomputed scores of SpliceAI and use a copy of the available [VEP plugin](https://github.com/Ensembl/VEP_plugins/blob/release/109/SpliceAI.pm) to annotate the VEP output with the classifications from the this file.

#### AnnotSV
[AnnotSV](https://lbgi.fr/AnnotSV/) is a program for annotating and ranking structural variations from genomes of several organisms.

We run the AnnotSV application in the VIP pipeline and use a VEP plugin to annotate the VEP output with the scores from the AnnotSV output file.

#### HPO
A file based on the HPO [phenotype_to_genes.txt](http://purl.obolibrary.org/obo/hp/hpoa/phenotype_to_genes.txt) is used to annotate VEP consequences with the inheritance modes associated with the gene of this consequence.

#### Inheritance
A file based on the [CGD database](https://research.nhgri.nih.gov/CGD/) is used to annotate VEP consequences with the inheritance modes associated with the gene of this consequence.

#### Grantham
The [Grantham score](https://www.science.org/doi/10.1126/science.185.4154.862) attempts to predict the distance between two amino acids, in an evolutionary sense. A lower Grantham score reflects less evolutionary distance. A higher Grantham score reflects a greater evolutionary distance.

We use a copy of the VEP plugin by Duarte Molha to annotate the VEP output with  Grantham scores.
