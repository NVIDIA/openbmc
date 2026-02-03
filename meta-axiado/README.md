Introduction
------------

This repository contains the layers for Axiado TCU.

* meta-common

  This layer contains .bbappend to revise the general recipes in OpenBMC.

* meta-evk

  This layer contains the basic builds for Axiado TCU.

* meta-amd/meta-intel/meta-nvidia

  These layers contain the reference builds for AMD/Intel/Nvidia platforms based on Axiado TCU.

Others
------

* recipes-axiado

  This dirctory contains Axiado-specific tools such as TDFU sysproxy etc.

* recipes-bsp

  This dirctory contains Axiado u-boot and recipes.

* recipes-kernel

  This dirctory contains Axiado Linux kernel and modules.

Additional information
----------------------

Axiado offers two versions of recipes:
v1.0 for internal access
v0.1 for external build which includes pre-built binaries

Setting up
----------

1) Download the source

```sh
git clone https://github.com/axiado/nvbmc.git
cd nvbmc
git clone https://github.com/axiado/meta-axiado-nvbmc.git meta-axiado
```

2) Target hardware

Refer the README in meta-* for available machine

```sh
. setup gb200nvl-bmc-axiado-github
```

3) Build
```sh
bitbake obmc-phosphor-image
```
