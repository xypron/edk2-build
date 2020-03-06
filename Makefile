# SPDX-License-Identifier: BSD-2-Clause
#
# Copyright 2019, Heinrich Schuchardt <xypron.glpk@gmx.de>
#
# Build tianocore/edk2 Shell.efi, SCT for x86_64

NPROC=${shell nproc}

UID="${shell id -u $(USER)}"
PWD:=${shell pwd}
export WORKSPACE:=$(PWD)
export EDK_TOOLS_PATH=$(PWD)/edk2/BaseTools
export CONF_PATH=$(PWD)/edk2/Conf
export GCC5_X64_PREFIX=
export PACKAGES_PATH=$(PWD)/edk2:$(PWD)/edk2-test/uefi-sct
export PATH:=$(PWD)/edk2/BaseTools/BinWrappers/PosixLike/:$(PATH)

all:
	make prepare
	make build-shell

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
	build -a X64 -p SctPkg/UEFI/UEFI_SCT.dsc -n $(NPROC)
	cd Build/UefiSct/RELEASE_GCC5 && \
	../../../edk2-test/uefi-sct/SctPkg/CommonGenFramework.sh \
	uefi_sct X64 InstallSct.efi

build-shell:
	build -a X64 -p ShellPkg/ShellPkg.dsc
	test -d ../u-boot-build/tftp && \
	cp Build/Shell/RELEASE_GCC5/X64/ShellPkg/Application/Shell/Shell/OUTPUT/Shell.efi \
	../u-boot-build/tftp/Shell_x64.efi

clean:
	build cleanall
