# Installation
```bash
git clone https://github.com/molgenis/vip
bash vip/install.sh
```
By default, the installation script downloads resources for both GRCh37 and GRCh38 assemblies.

## Options
Use `--assembly` to limit the downloaded resources to a specific assembly:
```bash
bash vip/install.sh --assembly GRCh37
bash vip/install.sh --assembly GRCh38
```
