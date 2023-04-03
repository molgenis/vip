# Key features
VIP is an easy to install, easy to use, portable and flexible pipeline implemented using [Nextflow](https://www.nextflow.io/).
Features include:

- Workflows for a broad range of input file types: `bam`, `cram`, `fastq`, `g.vcf`, `vcf`
- Produces stand-alone variant interpretation HTML report with integrated genome browser  
- Long-read sequencing support (Oxford Nanopore, PacBio HiFi)
- Short-read sequencing support (Illumina, both single and paired-end reads)
- Supports GRCh37 and GRCh38
- Short variant detection
    - Limitation: VIP currently does not support short variant detection on Mitochondrial DNA
- Structural variant detection
- Consequence-agnostic
- Rich set of variant annotations
- Pathogenic variant prioritization [(CAPICE)](https://github.com/molgenis/capice)
- Phenotype support [(HPO)](https://hpo.jax.org/)
- Inheritance matching [(VIP inheritance matcher)](https://github.com/molgenis/vip-inheritance-matcher)
- Variant classification and filtration using customizable decision trees
- Variant reporting using customizable report templates
- Quick reanalysis