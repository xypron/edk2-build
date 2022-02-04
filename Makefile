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
export GCC5_ARM_PREFIX=arm-linux-gnueabi-
export CROSS_COMPILE_32=arm-linux-gnueabi-
export PACKAGES_PATH=$(CURDIR)/edk2:$(CURDIR)/edk2-test/uefi-sct
export PATH:=$(CURDIR)/edk2/BaseTools/BinWrappers/PosixLike/:$(PATH)

.PHONY: all prepare build-sct sct-image
.SILENT: chmode

all:
	make prepare
	make build-sct
	make sct-image

edk2:
	git clone -v https://github.com/tianocore/edk2 edk2
	cd edk2 && python3 BaseTools/Scripts/SetupGit.py
	cd edk2 && git submodule update --init

edk2-test:
	git clone -v https://github.com/tianocore/edk2-test edk2-test
	cd edk2-test && git submodule update --init
	cd edk2-test && python3 ../edk2/BaseTools/Scripts/SetupGit.py

prepare: edk2
	cd edk2 && git submodule update --init
	cd edk2/BaseTools/Source/C/BrotliCompress/brotli && \
	git format-patch 0a3944c8c99b8d10cc4325f721b7c273d2b41f7b~..0a3944c8c99b8d10cc4325f721b7c273d2b41f7b && \
	git am 0001-Fix-VLA-parameter-warning-893.patch
	cd edk2/MdeModulePkg/Library/BrotliCustomDecompressLib/brotli && \
	git format-patch 0a3944c8c99b8d10cc4325f721b7c273d2b41f7b~..0a3944c8c99b8d10cc4325f721b7c273d2b41f7b && \
	git am 0001-Fix-VLA-parameter-warning-893.patch
	cd edk2 && source edksetup.sh --reconfig
	cp target.txt edk2/Conf
	cd edk2 && make -C BaseTools -j${NPROC}

build-genbin:
	cp edk2-test/uefi-sct/SctPkg/Tools/Source/GenBin \
	edk2/BaseTools/Source/C -r
	cd edk2/BaseTools/Source/C/GenBin && make
	cp edk2/BaseTools/Source/C/bin/GenBin \
	edk2/BaseTools/BinWrappers/PosixLike/

Shell_arm.efi:
	build -a ARM -p ShellPkg/ShellPkg.dsc -n $(NPROC)
	cp Build/Shell/RELEASE_GCC5/ARM/ShellPkg/Application/Shell/Shell/OUTPUT/Shell.efi \
	Shell_arm.efi

build-sct: edk2-test
	test -f edk2/BaseTools/BinWrappers/PosixLike/GenBin || \
	make build-genbin
	test -h SctPkg || ln -s edk2-test/uefi-sct/SctPkg/ SctPkg
	SctPkg/build.sh ARM GCC RELEASE

chmode:
	# virt-make-fs needs read access
	if [ ! $$(stat -c "%a" /boot/vmlinuz-$$(uname -r)) = 644 ]; then \
	echo sudo chmod 644 /boot/vmlinuz-$$(uname -r) && \
	sudo chmod 644 /boot/vmlinuz-$$(uname -r); fi

sct-image: Shell_arm.efi chmode
	rm -rf mnt
	mkdir -p mnt
	echo scsi scan > efi_shell.txt
	echo load scsi 0:1 \$${kernel_addr_r} Shell.efi >> efi_shell.txt
	echo bootefi \$${kernel_addr_r} >> efi_shell.txt
	mkimage -T script -n 'run EFI shell' -d efi_shell.txt mnt/boot.scr
	cp startup.nsh mnt/
	touch mnt/run
	cp Build/UefiSct/RELEASE_GCC5/SctPackageARM/ARM/* mnt/ -R
	cp Shell_arm.efi mnt/Shell.efi
	mkdir -p mnt/Sequence
	cp uboot.seq mnt/Sequence/
	virt-make-fs --partition=gpt --size=128M --type=vfat mnt sct-arm.img

clean:
	build cleanall
