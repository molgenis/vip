# Key features
VIP is an easy to install, easy to use, portable and flexible pipeline implemented using [Nextflow](https://www.nextflow.io/).
Features include:

- Workflows for a broad range of input file types: `pod5`, `bam`, `cram`, `fastq`, `g.vcf`, `vcf`
- Produces stand-alone variant interpretation HTML report with integrated genome browser  
- Long-read sequencing support (Oxford Nanopore, PacBio HiFi)
- Supports base modification in `cram` files with methylation tags: [SAMtags](https://samtools.github.io/hts-specs/SAMtags.pdf)
- Supports bedmethyl visualisation in genome browser 
- Short-read sequencing support (Illumina, both single and paired-end reads)
- Supports GRCh38, supports GRCh37 and T2T via liftover
- Short variant detection
- Structural variant detection
- Short tandem repeat detection
- Consequence-agnostic
- Rich set of variant annotations
- Pathogenic variant prioritization [(CAPICE)](https://github.com/molgenis/capice)
- Phenotype support [(HPO)](https://hpo.jax.org/)
- Inheritance matching [(VIP inheritance matcher)](https://github.com/molgenis/vip-inheritance-matcher)
- Variant classification and filtration using customizable decision trees
- Variant reporting using customizable report templates
- Quick reanalysis