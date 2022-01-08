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

edk2:
	git clone -v https://github.com/tianocore/edk2 edk2
	cd edk2 && git submodule update --init
	cd edk2/BaseTools/Source/C/BrotliCompress/brotli && \
	git format-patch 0a3944c8c99b8d10cc4325f721b7c273d2b41f7b~..0a3944c8c99b8d10cc4325f721b7c273d2b41f7b && \
	git am 0001-Fix-VLA-parameter-warning-893.patch
	cd edk2/MdeModulePkg/Library/BrotliCustomDecompressLib/brotli && \
	git format-patch 0a3944c8c99b8d10cc4325f721b7c273d2b41f7b~..0a3944c8c99b8d10cc4325f721b7c273d2b41f7b && \
	git am 0001-Fix-VLA-parameter-warning-893.patch
	cd edk2 && python3 BaseTools/Scripts/SetupGit.py

prepare: edk2
	test -d edk2-test || git clone -v \
	https://github.com/tianocore/edk2-test edk2-test
	test -L SctPkg || \
	(rm -rf SctPkg && ln -s edk2-test/uefi-sct/SctPkg/ SctPkg)
	cd edk2 && source edksetup.sh --reconfig
	cp target.txt edk2/Conf
	cd edk2 && make -C BaseTools -j${NPROC}

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
	test -h SctPkg || ln -s edk2-test/uefi-sct/SctPkg/ SctPkg
	SctPkg/build.sh AARCH64 GCC RELEASE

sct-image:
	mkdir -p mnt
	sudo umount mnt || true
	rm -f sct-arm64.part1
	/sbin/mkfs.vfat -F 32 -C sct-arm64.part1 131071
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
