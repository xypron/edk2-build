# SPDX-License-Identifier: BSD-2-Clause
#
# Copyright 2019, Heinrich Schuchardt <xypron.glpk@gmx.de>
#
# Build tianocore/edk2 Shell.efi

SHELL:=/bin/bash
NPROC=${shell nproc}

UID="${shell id -u $(USER)}"
PWD:=${shell pwd}
export WORKSPACE:=$(CURDIR)
export BASE_TOOLS_PATH=$(CURDIR)/edk2/BaseTools
export EDK_TOOLS_PATH=$(CURDIR)/edk2/BaseTools
export CONF_PATH=$(CURDIR)/edk2/Conf
export GCC5_AARCH64_PREFIX=aarch64-linux-gnu-
export PACKAGES_PATH=$(CURDIR)/edk2:$(CURDIR)/edk2-test/uefi-sct
export PATH:=$(CURDIR)/edk2/BaseTools/BinWrappers/PosixLike/:$(PATH)

all:
	make prepare
	make build-shell
	make build-sct
	make sct-image

prepare:
	test -d edk2 || git clone -v \
	https://github.com/tianocore/edk2 edk2
	cd edk2 && git submodule update --init
	test -d edk2-test || git clone -v \
	https://github.com/tianocore/edk2-test edk2-test
	cp target.txt edk2/Conf
	cd edk2 && git checkout edk2-stable202002
	cd edk2 && make -C BaseTools -j${NPROC}
	cd edk2 && source edksetup.sh

build-genbin:
	cp edk2-test/uefi-sct/SctPkg/Tools/Source/GenBin \
	edk2/BaseTools/Source/C -r
	cd edk2/BaseTools/Source/C/GenBin && make
	cp edk2/BaseTools/Source/C/bin/GenBin \
	edk2/BaseTools/BinWrappers/PosixLike/

build-shell:
	build -a AARCH64 -p ShellPkg/ShellPkg.dsc -n $(NPROC)
	find Build/ -name '*.efi'

build-sct:
	test -f edk2/BaseTools/BinWrappers/PosixLike/GenBin || \
	make build-genbin
	build -a AARCH64 -p SctPkg/UEFI/UEFI_SCT.dsc -n $(NPROC)
	cd Build/UefiSct/RELEASE_GCC5 && \
	../../../edk2-test/uefi-sct/SctPkg/CommonGenFramework.sh \
	uefi_sct AARCH64 InstallSct.efi

sct-image:
	mkdir -p mnt
	sudo umount mnt || true
	rm -f sct-arm64.part1
	/sbin/mkfs.vfat -C sct-arm64.part1 131071
	sudo mount sct-arm64.part1 mnt -o uid=$(UID)
	echo scsi scan > efi_shell.txt
	echo load scsi 0:1 \$${kernel_addr_r} Shell.efi >> efi_shell.txt
	echo bootefi \$${kernel_addr_r} >> efi_shell.txt
	mkimage -T script -n 'run EFI shell' -d efi_shell.txt mnt/boot.scr
	cp startup.nsh mnt/
	touch mnt/run
	cp Build/UefiSct/RELEASE_GCC5/SctPackageAARCH64/AARCH64/* mnt/ -R
	cp Build/Shell/RELEASE_GCC5/AARCH64/ShellPkg/Application/Shell/Shell/OUTPUT/Shell.efi mnt/
	mkdir -p mnt/Sequence
	cp uboot.seq mnt/Sequence/
	sudo umount mnt || true
	dd if=/dev/zero of=sct-arm64.img bs=1024 count=1 seek=1023
	cat sct-arm64.part1 >> sct-arm64.img
	rm sct-arm64.part1 efi_shell.txt
	echo -e "image1: start=2048, type=ef\n" | \
	/sbin/sfdisk sct-arm64.img

clean:
	build cleanall
