# Resource Update Guide

## Purpose

This guide describes how to update tools and resources used by VIP.

## Overview

Pipeline dependencies are divided into tools and resources.

### Tools

Tools are software components packaged as [Apptainer](https://apptainer.org/) container images.

#### Examples

- BCFtools
- Minimap2
- Mosdepth

#### Updates typically involve

- Updating the `.def` file
- Building a new `.sif` image
- Uploading the `.sif` to registry
- Updating the pipeline to use the new `.sif`
- Validation

### Resources

Resources are non-executable datasets or configuration assets used by tools during analysis.

#### Examples

- ClinVar
- HPO
- Classification tree
- Report template

#### Updates typically involve

- Uploading the resources to registry
- Updating the pipeline to use the new resource
- Validation

## Updating Tools

Decide whether this tool requires default or exceptional update procedure.

### Default

- Locate `<tool>.def` file in `utils/apptainer/def`
- Update tool version number in the `<tool>.def` file
- Update tool version number in the `<tool>.def` filename
- Update tool version number in `utils/apptainer/makefile`
- Run `make <tool>`
- Ensure that filename was changed to prevent file overwrite in next step as well as prevent user caching issues
- Upload `sif/<tool_with_updated_filename>.sif` to https://download.molgeniscloud.org/downloads/vip/images
- Run `md5sum sif/<tool_with_updated_filename>.sif`
- Update `<tool_with_updated_filename>.sif` filename and checksum in `/install_data.sh` located in function
  `install_files()`
- Update `<tool_with_updated_filename>.sif` in `config/nxf_<workflow>.config`

### Exceptions

Exceptional update procedure might exist for some tools, contact @bartcharbon or @dennishendriksen.

## Updating Resources

Decide whether this resource requires default or exceptional update procedure.

### Default

- Ensure that resource filename was changed to prevent file overwrite in next step as well as prevent user caching
  issues
- Upload `<resource>` to https://download.molgeniscloud.org/downloads/vip/resources or the relevant subfolder
- Run `md5sum <resource>`
- Update `<resource>` filename and checksum in `/install_data.sh` located in function `install_files()`
- Update references to `<resource>` in pipeline code

### Exceptions

Exceptional update procedure might exist for some tools, contact @bartcharbon or @dennishendriksen.