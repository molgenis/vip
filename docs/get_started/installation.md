# Installation

## Default

```bash
curl -sSL https://download.molgeniscloud.org/downloads/vip/install.sh | bash
```

```
VIP feat/installer_improvements installation running...
VIP feat/installer_improvements installation completed, execute vip/v8.4.1/vip.sh to get started
```

## EasyBuild

HPC systems running [EasyBuild](https://easybuild.io/) can install VIP by adapting the `/apps` paths in
these [easyconfig files](https://github.com/molgenis/take-it-easyconfigs/tree/main/v/vip) to your local environment.

## Customized

Alternatively the VIP installer can be called providing command line parameters to change the behaviour of the
installer:

```
bash install.sh [-i <vip_install_dir>] [-d <data_dir>] [-u <url>] [-p]
-u, --url       base url to download VIP resources from
-d, --data_dir  directory where VIP resources should be installed
-i, --vip_dir   directory where the VIP software should be installed
-p, --prune     remove resources from previous VIP installs that are not required for this version.
-h, --help
```