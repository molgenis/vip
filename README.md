# Variant Interpretation Pipeline

## Requirements
- [Nextflow](https://www.nextflow.io/)
- [Singularity](https://sylabs.io/singularity/)
- [Ensembl VEP cache](https://www.ensembl.org/info/docs/tools/vep/script/vep_cache.html)
- [Reference assembly](https://www.ncbi.nlm.nih.gov/grc/human)
- [AnnotSV annotations](https://github.com/lgmgeo/AnnotSV)

### Optional
- [gnomAD](https://gnomad.broadinstitute.org/) (CC0 1.0 license)
- [VKGL](https://vkgl.molgeniscloud.org/) (CC BY-NC-SA 4.0 license)
- [SpliceAI](https://basespace.illumina.com/s/otSPW8hnhaZR) (free for academic and not-for-profit use)

## Installation
```
git clone https://github.com/molgenis/vip
bash vip/resources/singularity/build.sh
```

## Usage
```
nextflow run vip/main.nf \
  --singularity_binds <paths> \
  --singularity_image_dir <path> \
  --annotate_vep_cache_dir <path> \
  --input <path> \
  --reference <path> \
  --outputDir <path>
```
see [nextflow.config](https://github.com/molgenis/vip/blob/master/nextflow.config) for additional parameters.
