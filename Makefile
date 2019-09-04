# SPDX-License-Identifier: BSD-2-Clause
#
# Copyright 2019, Heinrich Schuchardt <xypron.glpk@gmx.de>
#
# Build tianocore/edk2 Shell.efi

NPROC=${shell nproc}

UID="${shell id -u $(USER)}"
PWD:=${shell pwd}
export WORKSPACE:=$(PWD)/edk2/
export EDK_TOOLS_PATH=$(PWD)/edk2/BaseTools
export CONF_PATH=$(PWD)/edk2/Conf
export GCC5_AARCH64_PREFIX=aarch64-linux-gnu-
export PACKAGES_PATH=$(PWD)/edk2
export PATH:=$(PWD)/edk2/BaseTools/BinWrappers/PosixLike/:$(PATH)

all:
	make prepare
	make build-shell
	make build-sct
	make sct-image

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
	cd edk2 && BaseTools/BinWrappers/PosixLike/build -a AARCH64 \
	-p SctPkg/UEFI/UEFI_SCT.dsc
	cd edk2/Build/UefiSct/RELEASE_GCC5 && \
	../../../../edk2-test/uefi-sct/SctPkg/CommonGenFramework.sh \
	uefi_sct AARCH64 InstallSct.efi

build-shell:
	cd edk2 && BaseTools/BinWrappers/PosixLike/build -a AARCH64 \
	-p ShellPkg/ShellPkg.dsc
	find edk2/Build/ -name '*.efi'

sct-image:
	mkdir -p mnt
	sudo umount mnt || true
	rm -f sct-arm64.part1
	/sbin/mkfs.vfat -C sct-arm64.part1 131071
	sudo mount sct-arm64.part1 mnt -o uid=$(UID)
	cp ../edk2/ShellBinPkg/UefiShell/AArch64/Shell.efi mnt/
	echo scsi scan > efi_shell.txt
	echo load scsi 0:1 \$${kernel_addr_r} Shell.efi >> efi_shell.txt
	echo bootefi \$${kernel_addr_r} \$${fdtcontroladdr} >> efi_shell.txt
	mkimage -T script -n 'run EFI shell' -d efi_shell.txt mnt/boot.scr
	cp startup.nsh mnt/
	cp edk2/Build/UefiSct/RELEASE_GCC5/AARCH64/SctPkg/TestInfrastructure/SCT/Framework/Sct/OUTPUT/* mnt/ -R
	cp edk2/Build/Shell/RELEASE_GCC5/AARCH64/ShellPkg/Application/Shell/Shell/OUTPUT/Shell.efi mnt/
	cp uboot.seq mnt/
	sudo umount mnt || true
	dd if=/dev/zero of=sct-arm64.img bs=1024 count=1 seek=1023
	cat sct-arm64.part1 >> sct-arm64.img
	rm sct-arm64.part1 efi_shell.txt
	echo -e "image1: start=2048, type=ef\n" | \
	/sbin/sfdisk sct-arm64.img

clean:
	build cleanall
