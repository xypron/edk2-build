# SPDX-License-Identifier: BSD-2-Clause
#
# Copyright 2019, Heinrich Schuchardt <xypron.glpk@gmx.de>
#
# Build tianocore/edk2 Shell.efi

NPROC=${shell nproc}

PWD:=${shell pwd}
export WORKSPACE:=$(PWD)/edk2/
export EDK_TOOLS_PATH=$(PWD)/edk2/BaseTools
export CONF_PATH=$(PWD)/edk2/Conf
export GCC5_IA32_PREFIX=
export PATH:=$(PWD)/edk2/BaseTools/BinWrappers/PosixLike/:$(PATH)

all:
	make prepare
	make build-sct

prepare:
	test -d edk2 || git clone -v \
	https://github.com/tianocore/edk2 edk2
	test -d edk2-test || git clone -v \
	https://github.com/tianocore/edk2-test edk2-test
	test -d edk2/SctPkg || \
	(cd edk2 && ln -s ../edk2-test/uefi-sct/SctPkg SctPkg)
	test -d edk2/BaseTools/Source/C/bin/ || \
	(cd edk2 && pwd && bash -c '. edksetup.sh --reconfig')
	cp target.txt edk2/Conf
	cd edk2/BaseTools/Source/C && make -j $(NPROC)

build-sct:
	cd edk2 && ./SctPkg/build.sh IA32 GCC

build-shell:
	cd edk2 && BaseTools/BinWrappers/PosixLike/build -a IA32 \
	-p ShellPkg/ShellPkg.dsc
	find edk2/Build/ -name '*.efi'
	test -d ../u-boot-build/tftp && \
	cp edk2/Build/Shell/RELEASE_GCC5/IA32/ShellPkg/Application/Shell/Shell/OUTPUT/Shell.efi \
	../u-boot-build/tftp/Shell_i386.efi

clean:
	build cleanall
